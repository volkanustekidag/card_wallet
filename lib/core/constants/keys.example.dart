// Template for lib/core/constants/keys.dart (gitignored).
//
// CI copies this file to keys.dart so the project analyzes and tests
// without the real values. Release builds MUST use the real keys.dart:
// these names locate the users' existing encrypted Hive boxes and their
// Keychain / Keystore encryption keys. Shipping different values makes
// every existing wallet look empty.

const C_CARD_BOX_NAME = 'example_credit_cards';
const C_CARD_SECURE_STORAGE_KEY = 'example_credit_cards_key';

const I_CARD_BOX_NAME = 'example_iban_cards';
const I_CARD_SECURE_STORAGE_KEY = 'example_iban_cards_key';

const LOGIN_BOX_NAME = 'example_login';
const LOGIN_SECURE_STORAGE_KEY = 'example_login_key';

const LOYALTY_CARD_BOX_NAME = 'example_loyalty_cards';
const LOYALTY_CARD_SECURE_STORAGE_KEY = 'example_loyalty_cards_key';
