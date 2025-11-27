enum EnergyLevel {
  low('Low Battery'),
  medium('Balanced'),
  high('Fully Charged');
  
  final String displayName;
  const EnergyLevel(this.displayName);
}
