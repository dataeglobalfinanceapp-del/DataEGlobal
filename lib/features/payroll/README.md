# Employee Local Data Flow

Employee data is accessed through `EmployeeService` instead of directly from
Payroll UI widgets.

1. Payroll creates or receives an `EmployeeService` through constructor
   injection.
2. `EmployeeService` uses the configured `EmployeeRepository` contract.
3. The default repository is `LocalEmployeeRepository`, which stores employee
   records in the local `LocalStore` folder under `savetep_employee_data_v1`.
4. `DefaultEmployeeSeedData` provides removable local-only seed employees.
   `LocalEmployeeRepository` applies them only when local employee storage is
   empty.
5. `EmployeeDataMigration` clears old local seeded employee records once and
   records the applied cleanup version so new employees are not deleted later.
6. New employees, profile edits, and removals are saved through
   `EmployeeService`, then the Payroll controller refreshes its working
   employee list from the saved records.
7. `AwsEmployeeRepository` implements the same contract so a future AWS client
   can be injected without changing Payroll UI code.

Payroll-specific fields such as regular hours, overtime hours, commission,
tips, reminders, and synced payroll expenses remain owned by the Payroll
feature and existing payroll services.
