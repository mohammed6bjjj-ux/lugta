/// Withdrawal requests use whole thousands of IQD. The remainder stays in the
/// wallet; never round a submitted amount up or silently change it.
const withdrawalAmountStep = 1000;

bool isWholeThousandWithdrawal(int amount) =>
    amount > 0 && amount % withdrawalAmountStep == 0;

int maximumWholeThousandWithdrawal(int balance) =>
    balance <= 0 ? 0 : (balance ~/ withdrawalAmountStep) * withdrawalAmountStep;
