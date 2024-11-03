import plaid
from datetime import datetime, timedelta
from firebase_admin import initialize_app, firestore
from firebase_functions import https_fn
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.transactions_sync_request import TransactionsSyncRequest
from plaid.api import plaid_api

import os
from openai import OpenAI

# Initialize Firebase
initialize_app()

# Get Plaid config
plaid_config = plaid.Configuration(
    host=plaid.Environment.Sandbox,
    api_key={
        'clientId': os.environ.get('CLIENT_ID'),
        'secret': os.environ.get('SECRET')
    }
)

client = plaid_api.PlaidApi(plaid.ApiClient(plaid_config))


# create fake user and data
@https_fn.on_call()
def initiate_plaid_link(req: https_fn.CallableRequest) -> dict:
    """Creates a link token and stores it in Firestore"""
    try:
        db = firestore.client()
        user_id = req.auth.uid
        if not user_id:
            raise ValueError("User must be authenticated")

        request = LinkTokenCreateRequest(
            products=[Products('auth'), Products(
                'transactions'), Products('identity')],
            client_name="MoonWallet",
            country_codes=[CountryCode('US')],
            language='en',
            user=LinkTokenCreateRequestUser(
                client_user_id=user_id
            ),
        )

        response = client.link_token_create(request)

        # Store link token
        db.collection('users').document(user_id).set({
            'plaid_link_token': response.link_token,
            'link_token_created': firestore.SERVER_TIMESTAMP
        }, merge=True)

        return {'link_token': response.link_token}
    except Exception as e:
        return {'error': str(e)}


@https_fn.on_call()
def store_plaid_data(req: https_fn.CallableRequest) -> dict:
    """
    Fetches and stores all Plaid data (accounts, balances, transactions) 
    for a user after successful link
    """
    try:
        db = firestore.client()
        user_id = req.auth.uid
        public_token = req.data.get('public_token')

        print(public_token)

        if not user_id or not public_token:
            raise ValueError("Missing required parameters")

        # Exchange public token
        exchange_response = client.item_public_token_exchange(
            plaid.model.item_public_token_exchange_request.ItemPublicTokenExchangeRequest(
                public_token=public_token
            )
        )

        access_token = exchange_response.access_token
        item_id = exchange_response.item_id

        # Store tokens
        user_ref = db.collection('users').document(user_id)
        user_ref.set({
            'plaid_access_token': access_token,
            'plaid_item_id': item_id,
            'last_sync': firestore.SERVER_TIMESTAMP
        }, merge=True)

        # Fetch accounts and balances
        accounts_response = client.accounts_get(
            plaid.model.accounts_get_request.AccountsGetRequest(
                access_token=access_token
            )
        )

        print(accounts_response.accounts)

        # Store accounts
        try:
            for account in accounts_response.accounts:
                db.collection('users').document(user_id).collection('accounts').document(account.account_id).set({
                    'name': account.name,
                    'official_name': account.official_name,
                    # Convert to string if necessary
                    'type': account.type.value if hasattr(account.type, 'value') else str(account.type),
                    # Convert to string if necessary
                    'subtype': account.subtype.value if hasattr(account.subtype, 'value') else str(account.subtype),
                    'mask': account.mask,
                    'balances': {
                        'current': account.balances.current,
                        'available': account.balances.available,
                        'limit': account.balances.limit if hasattr(account.balances, 'limit') else None
                    },
                    'last_updated': firestore.SERVER_TIMESTAMP
                }, merge=True)
        except Exception as e:
            print("Error storing accounts:", e)

        try:
            request = TransactionsSyncRequest(
                access_token=access_token
            )

            # First API call
            response = client.transactions_sync(request)

            print(response)
            transactions = response['added']

            # Store transactions in Firestore
            store_transactions(transactions, user_id, db)

            # Handle pagination to retrieve all transactions
            while response['has_more']:
                request = TransactionsSyncRequest(
                    access_token=access_token,
                    cursor=response['next_cursor']
                )
                response = client.transactions_sync(request)
                print(response)
                transactions = response['added']

                # Store new transactions in Firestore
                store_transactions(transactions, user_id, db)

            return {'success': True}

        except Exception as e:
            print("Error storing transactions:", e)
    except Exception as e:
        return {'error': str(e)}


def store_transactions(transactions, user_id, db):
    # Loop through transactions and store each one in Firestore
    for transaction in transactions:
        db.collection('users').document(user_id).collection('transactions').document(transaction.transaction_id).set({
            'account_id': transaction.account_id,
            'amount': transaction.amount,
            'date': datetime.combine(transaction.date, datetime.min.time()),
            'name': transaction.name,
            'merchant_name': transaction.merchant_name,
            'payment_channel': transaction.payment_channel,
            'pending': transaction.pending,
            'category': transaction.personal_finance_category.primary if transaction.personal_finance_category else None,
            'subcategory': transaction.personal_finance_category.detailed if transaction.personal_finance_category else None,
            'logo': transaction.logo_url if transaction.logo_url else None,
            'timestamp': firestore.SERVER_TIMESTAMP
        }, merge=True)


@https_fn.on_call()
def get_transactions(req: https_fn.CallableRequest) -> dict:
    """Fetches transactions for a user"""
    try:
        db = firestore.client()
        user_id = req.auth.uid

        if not user_id:
            raise ValueError("User must be authenticated")

        all_transactions = db.collection('users').document(
            user_id).collection('transactions').stream()

        transactions = [{'transaction_id': doc.id, **doc.to_dict()}
                        for doc in all_transactions]

        # Sort transactions by date
        transactions.sort(key=lambda x: x['date'], reverse=True)

        print(transactions)
        return {'transactions': transactions}
    except Exception as e:
        print("Error", e)
        return {'error': str(e)}


@https_fn.on_call()
def get_ai_assistance(req: https_fn.CallableRequest) -> dict:
    """Returns AI assistance for a user, request includes user message"""
    try:
        db = firestore.client()
        user_id = req.auth.uid

        # get request message
        message = req.data.get('message')

        if not user_id:
            raise ValueError("User must be authenticated")

        user_ref = db.collection('users').document(user_id)
        accounts = user_ref.collection('accounts').stream()
        transactions = user_ref.collection('transactions').stream()

        accounts_data = [doc.to_dict() for doc in accounts]
        transactions_data = [doc.to_dict() for doc in transactions]

        prompt = f"""As an AI financial advisor, analyze the user's financial data and provide personalized advice. The user asks:

        "{message}"

        Financial Overview:
        - Accounts: {accounts_data}
        - Recent Transactions: {transactions_data}

        Requirements:
        1. Analyze spending patterns and account balances
        2. Identify specific opportunities for improvement
        3. Provide 2-3 actionable recommendations
        4. Consider both short-term and long-term financial health
        5. Keep response concise (3-4 sentences maximum)
        6. Use new lines and bullet points for clarity

        Response Guidelines:
        - Lead with the most impactful recommendation first
        - Include specific numbers when relevant
        - Focus on practical, achievable steps
        - Consider the user's current financial situation
        - Maintain a supportive, professional tone

        Note: Response should be direct and immediately useful without any prefacing or summary statements."""

        client = OpenAI(api_key=os.environ.get('OPENAI_SECRET'))

        chat_response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a concise financial advisor."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=50,
            temperature=0.7
        )

        print(chat_response.choices[0].message.content)

        return {'response': chat_response.choices[0].message.content}

    except Exception as e:
        print("Error", str(e))
        return {'error': str(e)}
