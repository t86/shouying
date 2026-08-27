import 'package:session/src/credential_transaction_coordinator.dart';
import 'package:session/src/credential_transaction_coordinator_native.dart'
    if (dart.library.js_interop) 'package:session/src/credential_transaction_coordinator_web.dart'
    as platform;

CredentialTransactionCoordinator createCredentialTransactionCoordinator() =>
    platform.createCredentialTransactionCoordinator();
