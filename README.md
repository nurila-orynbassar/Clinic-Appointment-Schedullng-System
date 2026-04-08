# Clinic Appointment Scheduling System
**Group Project | Role: Lead Database Developer**

A comprehensive Database Management System (DBMS) built from scratch to streamline clinic operations. This project covers the full development lifecycle, from complex relational schema design to a functional web-based interface.

## Team Collaboration & My Role
This project was a collaborative group effort. As the **Lead Database Developer**, my primary responsibilities included:
- **Backend Implementation:** Developed core PL/SQL packages, business logic functions, and critical security triggers.
- **Full-Stack Integration:** Built the front-end dashboard using Oracle APEX and linked it to the database backend.
- **Frontend Development:** Designing and linking the Oracle APEX App Builder interface to the database logic.

## Key Technical Features

### 1. Advanced Backend Logic (PL/SQL)
- **Modular Packages:** Integrated `reminder_scheduler`, `payments_billing`, and `reports_generator` packages for clean, maintainable, and reusable code.
- **Automated Business Rules:** - **Double-Booking Prevention:** Triggers to ensure doctors and rooms aren't overbooked.
  - **Payment Enforcement:** Logic ensuring appointments can't be marked "Completed" without a processed payment.
- **Analytics & Reporting:** Utilized **Explicit Cursors**, **Records**, and **Table Functions** to generate real-time doctor performance and clinic revenue reports.

### 2. Robust Database Design
- **Normalized Schema:** 10+ entities including Patients, Doctors, Appointments, Medical Records, Payments, and Prescriptions.
- **Data Integrity:** Implemented audit logging for deleted records and comprehensive **Exception Handling** to manage scheduling conflicts.
- **Collections:** Used **Bulk Collect** and **Nested Tables** for high-performance medicine and prescription handling.

### 3. User Interface (Oracle APEX)
Developed a functional 1-page dashboard in **App Builder** that allows:
- **Instant Search:** Find patient history and doctor availability.
- **CRUD Operations:** Securely insert, update, and delete appointments and medical records.
- **Real-time Validation:** UI fields are directly synced with database constraints and triggers.

## 🛠 Tech Stack
- **Database:** Oracle Database
- **Languages:** SQL, PL/SQL
- **Interface:** Oracle APEX (App Builder)
- **Design:** Crow's Foot ER Diagram (3NF)
