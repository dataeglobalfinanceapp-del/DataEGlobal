class SaveEmployeeRequest {
  final String id;
  final String fullName;
  final String birthday;
  final String phone;
  final String address;
  final String dateHire;
  final String jobType;
  final double rate;
  final String payMethod;
  final String linkW4;

  const SaveEmployeeRequest({
    this.id = '',
    required this.fullName,
    required this.birthday,
    required this.phone,
    required this.address,
    required this.dateHire,
    required this.jobType,
    required this.rate,
    this.payMethod = '',
    this.linkW4 = '',
  });
}
