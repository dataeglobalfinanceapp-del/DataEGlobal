import 'package:savetep/data/dto/save_employee_request.dart';

class DefaultEmployeeSeedData {
  static const int version = 1;

  static const List<SaveEmployeeRequest> employees = <SaveEmployeeRequest>[
    SaveEmployeeRequest(
      id: 'local-seed-employee-1',
      fullName: 'Maya Rodriguez',
      birthday: '03/14/1992',
      phone: '555-0148',
      address: '214 Maple Avenue, San Mateo, CA 94402',
      dateHire: '01/08/2024',
      jobType: 'Hourly',
      rate: 20,
    ),
    SaveEmployeeRequest(
      id: 'local-seed-employee-2',
      fullName: 'Noah Bennett',
      birthday: '09/27/1998',
      phone: '555-0263',
      address: '87 Cedar Lane, Burlingame, CA 94010',
      dateHire: '03/18/2024',
      jobType: 'Part Time',
      rate: 16.9,
    ),
    SaveEmployeeRequest(
      id: 'local-seed-employee-3',
      fullName: 'Olivia Martinez',
      birthday: '12/05/1990',
      phone: '555-0374',
      address: '640 Valencia Street, San Francisco, CA 94110',
      dateHire: '07/22/2023',
      jobType: 'Hourly',
      rate: 20,
    ),
    SaveEmployeeRequest(
      id: 'local-seed-employee-4',
      fullName: 'Liam Anderson',
      birthday: '06/19/1995',
      phone: '555-0485',
      address: '301 Harbor Drive, Redwood City, CA 94063',
      dateHire: '11/06/2023',
      jobType: 'Part Time',
      rate: 17.5,
    ),
    SaveEmployeeRequest(
      id: 'local-seed-employee-5',
      fullName: 'Sophia Patel',
      birthday: '02/11/1989',
      phone: '555-0596',
      address: '58 Mission Bay Boulevard, San Francisco, CA 94158',
      dateHire: '05/13/2022',
      jobType: 'Hourly',
      rate: 18.5,
    ),
    SaveEmployeeRequest(
      id: 'local-seed-employee-6',
      fullName: 'Ethan Brooks',
      birthday: '10/30/1987',
      phone: '555-0617',
      address: '1720 El Camino Real, Palo Alto, CA 94306',
      dateHire: '09/04/2021',
      jobType: 'Hourly',
      rate: 25,
    ),
  ];

  const DefaultEmployeeSeedData._();
}
