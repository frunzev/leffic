enum AmountMode {
  automatic(label: 'Auto', presetAmount: null),
  ten(label: '10', presetAmount: 10),
  twenty(label: '20', presetAmount: 20),
  custom(label: 'Custom', presetAmount: null);

  const AmountMode({required this.label, required this.presetAmount});

  final String label;
  final int? presetAmount;
}

class AmountChoice {
  const AmountChoice({required this.mode, required this.customAmount});

  static const AmountChoice automatic = AmountChoice(
    mode: AmountMode.automatic,
    customAmount: null,
  );

  final AmountMode mode;
  final int? customAmount;

  int? get amount {
    if (mode == AmountMode.custom) {
      return customAmount;
    }

    return mode.presetAmount;
  }

  AmountChoice withMode(AmountMode newMode) {
    return AmountChoice(mode: newMode, customAmount: customAmount);
  }

  AmountChoice withCustomAmount(int? newAmount) {
    return AmountChoice(mode: AmountMode.custom, customAmount: newAmount);
  }
}
