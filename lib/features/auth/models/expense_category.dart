enum ExpenseType { fixed, variable }

class ExpenseCategory {
  final String id;
  final String name;
  final ExpenseType expenseType;
  final String mindeeLabel;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.expenseType,
    String? mindeeLabel,
  }) : mindeeLabel = mindeeLabel ?? name;

  String get label => mindeeLabel;

  static const ExpenseCategory rents = ExpenseCategory(
    id: 'fixed.rents',
    name: 'RENTS',
    expenseType: ExpenseType.fixed,
    mindeeLabel: 'Rent',
  );
  static const ExpenseCategory utilities = ExpenseCategory(
    id: 'fixed.utilities',
    name: 'UTILITIES',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory electrical = ExpenseCategory(
    id: 'fixed.electrical',
    name: 'ELECTRICAL',
    expenseType: ExpenseType.fixed,
    mindeeLabel: 'electric',
  );
  static const ExpenseCategory fixedGas = ExpenseCategory(
    id: 'fixed.gas',
    name: 'GAS',
    expenseType: ExpenseType.fixed,
    mindeeLabel: 'gas',
  );
  static const ExpenseCategory fixedWater = ExpenseCategory(
    id: 'fixed.water',
    name: 'WATER',
    expenseType: ExpenseType.fixed,
    mindeeLabel: 'water',
  );
  static const ExpenseCategory payrollWages = ExpenseCategory(
    id: 'fixed.payroll_wages',
    name: 'PAYROLL & WAGES',
    expenseType: ExpenseType.fixed,
    mindeeLabel: 'Payroll',
  );
  static const ExpenseCategory employees = ExpenseCategory(
    id: 'fixed.employees',
    name: 'EMPLOYEES',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory employer = ExpenseCategory(
    id: 'fixed.employer',
    name: 'EMPLOYER',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory businessPhone = ExpenseCategory(
    id: 'fixed.business_phone',
    name: 'BUSINESS PHONE',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory businessInsurance = ExpenseCategory(
    id: 'fixed.business_insurance',
    name: 'BUSINESS INSURANCE',
    expenseType: ExpenseType.fixed,
    mindeeLabel: 'Insurance',
  );
  static const ExpenseCategory businessInternet = ExpenseCategory(
    id: 'fixed.internet',
    name: 'INTERNET',
    expenseType: ExpenseType.fixed,
    mindeeLabel: 'Internet',
  );
  static const ExpenseCategory posSystem = ExpenseCategory(
    id: 'fixed.pos_system',
    name: 'POS SYSTEM',
    expenseType: ExpenseType.fixed,
  );

  static const ExpenseCategory augustaRule = ExpenseCategory(
    id: 'variable.augusta_rule',
    name: 'AUGUSTA RULE',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory perDiemOther = ExpenseCategory(
    id: 'variable.per_diem_other',
    name: 'PER DIEM / OTHER',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory repair = ExpenseCategory(
    id: 'variable.repair',
    name: 'REPAIR',
    expenseType: ExpenseType.variable,
    mindeeLabel: 'Maintenance',
  );
  static const ExpenseCategory badDebts = ExpenseCategory(
    id: 'variable.bad_debts',
    name: 'BAD DEBTS',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory stateFranchiseTax = ExpenseCategory(
    id: 'variable.state_franchise_tax',
    name: 'STATE FRANCHISE TAX',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory localPropertyTax = ExpenseCategory(
    id: 'variable.local_property_tax',
    name: 'LOCAL PROPERTY TAX',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory businessLicense = ExpenseCategory(
    id: 'variable.business_license',
    name: 'BUSINESS LICENSE',
    expenseType: ExpenseType.variable,
    mindeeLabel: 'Business licenses and permits',
  );
  static const ExpenseCategory accounting = ExpenseCategory(
    id: 'variable.accounting',
    name: 'ACCOUNTING',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory mealAndEntertaiment = ExpenseCategory(
    id: 'variable.meal_and_entertaiment',
    name: 'MEAL AND ENTERTAIMENT',
    expenseType: ExpenseType.variable,
    mindeeLabel: 'Meal, entertainment',
  );
  static const ExpenseCategory giftsMax25 = ExpenseCategory(
    id: 'variable.gifts_max_25_per',
    name: 'GIFTS (MAX \$25/PER)',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory marketingAdvertise = ExpenseCategory(
    id: 'variable.marketing_advertise',
    name: 'MARKETING (ADVERTISE)',
    expenseType: ExpenseType.variable,
    mindeeLabel: 'Advertising and promotion',
  );
  static const ExpenseCategory depreciation = ExpenseCategory(
    id: 'variable.depreciation',
    name: 'DEPRECIATION',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory amortization = ExpenseCategory(
    id: 'variable.amortization',
    name: 'AMORTIZATION',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory rule179 = ExpenseCategory(
    id: 'variable.rule_179',
    name: 'RULE 179',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory useTax = ExpenseCategory(
    id: 'variable.use_tax',
    name: 'USE TAX',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory automobileTruck = ExpenseCategory(
    id: 'variable.automobile_truck',
    name: 'AUTOMOBILE & TRUCK',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory bankCharges = ExpenseCategory(
    id: 'variable.bank_charges',
    name: 'BANK CHARGES',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory computerSupplies = ExpenseCategory(
    id: 'variable.computer_supplies',
    name: 'COMPUTER & SUPPLIES',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory creditCollection = ExpenseCategory(
    id: 'variable.credit_collection',
    name: 'CREDIT & COLLECTION',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory deliveryFreight = ExpenseCategory(
    id: 'variable.delivery_freight',
    name: 'DELIVERY & FREIGHT',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory discounts = ExpenseCategory(
    id: 'variable.discounts',
    name: 'DISCOUNTS',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory duesSubscriptions = ExpenseCategory(
    id: 'variable.dues_subscriptions',
    name: 'DUES & SUBSCRIPTIONS',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory legalProfessinal = ExpenseCategory(
    id: 'variable.legal_professinal',
    name: 'LEGAL & PROFESSINAL',
    expenseType: ExpenseType.variable,
    mindeeLabel: 'professional fees',
  );
  static const ExpenseCategory entertaiment = ExpenseCategory(
    id: 'variable.entertaiment',
    name: 'ENTERTAIMENT',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory janitorial = ExpenseCategory(
    id: 'variable.janitorial',
    name: 'JANITORIAL',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory hikeKids = ExpenseCategory(
    id: 'variable.hike_kids',
    name: 'HIKE KIDS',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory laundryCleaning = ExpenseCategory(
    id: 'variable.laundry_cleaning',
    name: 'LAUNDRY & CLEANING',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory commission = ExpenseCategory(
    id: 'variable.commission',
    name: 'COMMISSION',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory spaChairTable = ExpenseCategory(
    id: 'variable.spa_chair_table',
    name: 'SPA CHAIR AND TABLE',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory saleTaxLink = ExpenseCategory(
    id: 'variable.sale_tax_link',
    name: 'SALE TAX (LINK)',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory office = ExpenseCategory(
    id: 'variable.office',
    name: 'OFFICE',
    expenseType: ExpenseType.variable,
    mindeeLabel: 'Office Supplies',
  );
  static const ExpenseCategory outsideServices = ExpenseCategory(
    id: 'variable.outside_services',
    name: 'OUTSIDE SERVICES',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory parkingFeesTolls = ExpenseCategory(
    id: 'variable.parking_fees_tolls',
    name: 'PARKING FEES & TOLLS',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory permitsFees = ExpenseCategory(
    id: 'variable.permits_fees',
    name: 'PERMITS & FEES',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory postage = ExpenseCategory(
    id: 'variable.postage',
    name: 'POSTAGE',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory pringting = ExpenseCategory(
    id: 'variable.pringting',
    name: 'PRINGTING',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory security = ExpenseCategory(
    id: 'variable.security',
    name: 'SECURITY',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory supplies = ExpenseCategory(
    id: 'variable.supplies',
    name: 'SUPPLIES',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory telephone = ExpenseCategory(
    id: 'variable.telephone',
    name: 'TELEPHONE',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory cellPhone = ExpenseCategory(
    id: 'variable.cell_phone',
    name: 'CELL PHONE',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory equipment = ExpenseCategory(
    id: 'variable.equipment',
    name: 'EQUIPMENT',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory smallTools = ExpenseCategory(
    id: 'variable.small_tools',
    name: 'SMALL TOOLS',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory trainningContEdu = ExpenseCategory(
    id: 'variable.trainning_cont_edu',
    name: 'TRAINNING / CONT EDU',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory travel = ExpenseCategory(
    id: 'variable.travel',
    name: 'TRAVEL',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory uniform = ExpenseCategory(
    id: 'variable.uniform',
    name: 'UNIFORM',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory merchantServices = ExpenseCategory(
    id: 'variable.merchant_services',
    name: 'MERCHANT SERVICES',
    expenseType: ExpenseType.variable,
    mindeeLabel: 'merchant accounting fees',
  );
  static const ExpenseCategory appFinance = ExpenseCategory(
    id: 'variable.app_finance',
    name: 'APP FINANCE',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory giftCard = ExpenseCategory(
    id: 'variable.gift_card',
    name: 'GIFT CARD',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory gasForMileage = ExpenseCategory(
    id: 'variable.gas_for_mileage',
    name: 'GAS FOR MILEAGE',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory contractor = ExpenseCategory(
    id: 'variable.contractor',
    name: 'CONTRACTOR',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory giftDonation = ExpenseCategory(
    id: 'variable.gift_donation',
    name: 'GIFT & DONATION',
    expenseType: ExpenseType.variable,
    mindeeLabel: 'donation',
  );
  static const ExpenseCategory businessLossTheft = ExpenseCategory(
    id: 'variable.business_loss_theft',
    name: 'BUSINESS LOSS AND THEFT',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory accountingPlanReimbursements = ExpenseCategory(
    id: 'variable.accounting_plan_reimbursements',
    name: 'ACCOUNTING PLAN REIMBURSEMENTS',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory insuranceVehicle = ExpenseCategory(
    id: 'variable.insurance_vehicle',
    name: 'INSURANCE VEHICLE',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory tradeMarkUsptoFee = ExpenseCategory(
    id: 'variable.trade_mark_uspto_fee',
    name: 'TRADE MARK USPTO FEE',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory interestLoanBusiness = ExpenseCategory(
    id: 'variable.interest_loan_business',
    name: 'INTEREST (LOAN BUSINESS)',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory petsControl = ExpenseCategory(
    id: 'variable.pets_control',
    name: 'PETS CONTROL',
    expenseType: ExpenseType.variable,
    mindeeLabel: 'pest control',
  );

  static const ExpenseCategory energy = ExpenseCategory(
    id: 'legacy.energy',
    name: 'Energy',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory loanObligation = ExpenseCategory(
    id: 'legacy.loan_obligation',
    name: 'Loan Obligation',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory foodPurchase = ExpenseCategory(
    id: 'legacy.food_purchase',
    name: 'Food Purchase',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory restaurantSupplies = ExpenseCategory(
    id: 'legacy.restaurant_supplies',
    name: 'Restaurant supplies',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory software = ExpenseCategory(
    id: 'legacy.software',
    name: 'software',
    expenseType: ExpenseType.variable,
  );

  static const ExpenseCategory payroll = ExpenseCategory(
    id: 'fixed.payroll_wages',
    name: 'Payroll',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory businessLicensesAndPermits = ExpenseCategory(
    id: 'variable.business_license',
    name: 'Business licenses and permits',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory advertisingAndPromotion = ExpenseCategory(
    id: 'variable.marketing_advertise',
    name: 'Advertising and promotion',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory pestControl = ExpenseCategory(
    id: 'variable.pets_control',
    name: 'pest control',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory maintenance = ExpenseCategory(
    id: 'variable.repair',
    name: 'Maintenance',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory insurance = ExpenseCategory(
    id: 'fixed.business_insurance',
    name: 'Insurance',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory rent = ExpenseCategory(
    id: 'fixed.rents',
    name: 'Rent',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory officeSupplies = ExpenseCategory(
    id: 'variable.office',
    name: 'Office Supplies',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory mealEntertainment = ExpenseCategory(
    id: 'variable.meal_and_entertaiment',
    name: 'Meal, entertainment',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory merchantAccountingFees = ExpenseCategory(
    id: 'variable.merchant_services',
    name: 'merchant accounting fees',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory gas = ExpenseCategory(
    id: 'fixed.gas',
    name: 'gas',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory water = ExpenseCategory(
    id: 'fixed.water',
    name: 'water',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory electric = ExpenseCategory(
    id: 'fixed.electrical',
    name: 'electric',
    expenseType: ExpenseType.fixed,
  );
  static const ExpenseCategory donation = ExpenseCategory(
    id: 'variable.gift_donation',
    name: 'donation',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory professionalFees = ExpenseCategory(
    id: 'variable.legal_professinal',
    name: 'professional fees',
    expenseType: ExpenseType.variable,
  );
  static const ExpenseCategory internet = ExpenseCategory(
    id: 'fixed.internet',
    name: 'Internet',
    expenseType: ExpenseType.fixed,
  );

  static const List<ExpenseCategory> values = <ExpenseCategory>[
    energy,
    loanObligation,
    payroll,
    businessLicensesAndPermits,
    foodPurchase,
    restaurantSupplies,
    advertisingAndPromotion,
    software,
    pestControl,
    internet,
    maintenance,
    insurance,
    rent,
    officeSupplies,
    mealEntertainment,
    merchantAccountingFees,
    gas,
    water,
    electric,
    donation,
    professionalFees,
  ];

  static const List<ExpenseCategory> onboardingCategories = <ExpenseCategory>[
    rents,
    utilities,
    electrical,
    fixedGas,
    fixedWater,
    payrollWages,
    employees,
    employer,
    businessPhone,
    businessInsurance,
    businessInternet,
    posSystem,
    augustaRule,
    perDiemOther,
    repair,
    badDebts,
    stateFranchiseTax,
    localPropertyTax,
    businessLicense,
    accounting,
    mealAndEntertaiment,
    giftsMax25,
    marketingAdvertise,
    depreciation,
    amortization,
    rule179,
    useTax,
    automobileTruck,
    bankCharges,
    computerSupplies,
    creditCollection,
    deliveryFreight,
    discounts,
    duesSubscriptions,
    legalProfessinal,
    entertaiment,
    janitorial,
    hikeKids,
    laundryCleaning,
    commission,
    spaChairTable,
    saleTaxLink,
    office,
    outsideServices,
    parkingFeesTolls,
    permitsFees,
    postage,
    pringting,
    security,
    supplies,
    telephone,
    cellPhone,
    equipment,
    smallTools,
    trainningContEdu,
    travel,
    uniform,
    merchantServices,
    appFinance,
    giftCard,
    gasForMileage,
    contractor,
    giftDonation,
    businessLossTheft,
    accountingPlanReimbursements,
    insuranceVehicle,
    tradeMarkUsptoFee,
    interestLoanBusiness,
    petsControl,
  ];

  static Map<String, ExpenseCategory> get onboardingById =>
      <String, ExpenseCategory>{
        for (final category in onboardingCategories) category.id: category,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExpenseCategory && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
