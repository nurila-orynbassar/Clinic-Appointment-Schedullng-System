--function 1--
create or replace function doc_availability(d_id   in number, d_date in date, d_time in varchar2)
return varchar2
is
cn number;
begin
select count(*)
into cn
from appointments
where doctor_id = d_id
and appointment_date = d_date
and appointment_time = d_time
and status = 'Scheduled';

if cn = 0 then
return 'Available';
else
return 'Busy';
end if;
end;

--function 2--
create or replace function room_availability(r_id number, r_date date, r_time varchar2)
return varchar2
is
cn number;
begin
select count(*)
into cn
from appointments
where room_id = r_id
and appointment_date = r_date
and appointment_time = r_time
and status = 'Scheduled';

if cn = 0 then
return 'Available';
else
return 'Busy';
end if;
end;

--function 3--
create or replace function fb_count(p_id number)
return number
is
cn number;
begin
select count(*)
into cn
from feedbacks
where patient_id = p_id;
return cn;
end;


--function 4--
create or replace function total_paid(p_patient_id number)
return number
is
v_total number;
begin
select nvl(sum(p.amount), 0)
into v_total
from payments p
join appointments a
on a.appointment_id = p.appointment_id
where a.patient_id = p_patient_id;
return v_total;
end;

--procedure 1--
create or replace procedure reschedule_appointment(p_appointment_id in number, p_new_date in date, p_new_time in varchar2, p_new_room_id in number)
is
v_doctor_id appointments.doctor_id%type;
v_old_room_id appointments.room_id%type;
v_room_id appointments.room_id%type;
v_doc_status varchar2(20);
v_room_status varchar2(20);
begin
select doctor_id, room_id
into v_doctor_id, v_old_room_id
from appointments
where appointment_id = p_appointment_id
and status = 'Scheduled';
v_room_id := nvl(p_new_room_id, v_old_room_id);

v_doc_status := doc_availability(v_doctor_id, p_new_date, p_new_time);
if v_doc_status <> 'Available' then
raise_application_error(-20011, 'Doctor is busy at the new date and time.');
end if;

v_room_status := room_availability(v_room_id, p_new_date, p_new_time);
if v_room_status <> 'Available' then
raise_application_error(-20012,'Room is busy at the new date and time.');
end if;

update appointments
set appointment_date = p_new_date,
appointment_time = p_new_time,
room_id = v_room_id
where appointment_id = p_appointment_id;
dbms_output.put_line('Appointment successfully rescheduled.');
exception
when no_data_found then
raise_application_error(-20013,'Appointment not found or not in status "Запланировано".');
end;

--procedure 2--
create or replace procedure complete_appointment(p_id number, p_diag varchar2, p_treat varchar2)
is
begin
update appointments
set status = 'Completed'
where appointment_id = p_id;

insert into medical_records(record_id, patient_id, appointment_id, diagnosis, treatment, record_date)
select seq_record.nextval, patient_id, appointment_id, p_diag, p_treat,
sysdate
from appointments
where appointment_id = p_id;
end;


--cursor and record 1--
declare
type t_bonus is record(
        pid number,
        name varchar2(200),
        visits number,
        paid number,
        bonus number
    );
cursor cur is
select p.patient_id, p.first_name||' '||p.last_name name,
        count(a.appointment_id) visits, nvl(sum(pm.amount),0) paid
 from patients p
 left join appointments a on p.patient_id=a.patient_id
 left join payments pm on a.appointment_id=pm.appointment_id
 group by p.patient_id,p.first_name,p.last_name;

 r t_bonus;
begin
open cur;
   loop
      fetch cur into r.pid,r.name,r.visits,r.paid;
      exit when cur%notfound;

     if r.visits>=15 then
      r.bonus:=30;
     elsif r.paid>=150000 then
         r.bonus:=20;
     else
         r.bonus:=5;
   end if;

   dbms_output.put_line(
   r.name||' | visits: '||r.visits|| ' | paid: '||r.paid|| ' | bonus: '||r.bonus||'%');
   end loop;
   close cur;
end;

--cursor and record 2--
declare
r appointments%rowtype;  
begin
begin
select * into r
from appointments
here appointment_id = 10;
dbms_output.put_line( 'Appointment details:'  ' patient='  r.patient_id  ', doctor='  r.doctor_id ||
            ', status='  r.status  ', date='  to_char(r.appointment_date, 'dd-mon-yyyy') 
            ', time=' || r.appointment_time);

exception
when no_data_found then
dbms_output.put_line('No appointment found with id 10');
end;
end;



--cursor and record 3--
declare
type t_discount is record(
    pid number,
    name varchar2(200),
    visits number,
    paid number,
    disc number
);
cursor cur is
select p.patient_id, p.first_name||' '||p.last_name name,
count(a.appointment_id) visits,
nvl(sum(pm.amount),0) paid
from patients p
left join appointments a on p.patient_id=a.patient_id
left join payments pm on a.appointment_id=pm.appointment_id
group by p.patient_id,p.first_name,p.last_name;

r t_discount;
begin
open cur;
loop
fetch cur into r.pid,r.name,r.visits,r.paid;
exit when cur%notfound;
if r.paid>=100000 then
r.disc:=20;
elsif r.visits>=5 then
r.disc:=10;
else
r.disc:=0;
end if;
dbms_output.put_line(r.name||' | visits: '||r.visits||
    ' | paid: '||r.paid||
    ' | discount: '||r.disc||'%');
end loop;
close cur;
end;


--cursor and record 4--
declare
pid constant medical_records.patient_id%type := 205; 
type t_rec is record (
rid medical_records.record_id%type,
rdate medical_records.record_date%type,
diag medical_records.diagnosis%type,
treat medical_records.treatment%type,
presid prescriptions.prescription_id%type 
);
cursor c_hist is
select mr.record_id, mr.record_date, mr.diagnosis, mr.treatment, mr.prescription_id as presid
from medical_records mr
where mr.patient_id = pid
order by mr.record_date desc;
v_rec t_rec;
v_med varchar2(4000);
begin
select first_name ||' '|| last_name into v_med
from patients
where patient_id = pid;
dbms_output.put_line('history:'||v_med);
open c_hist;
loop
fetch c_hist into v_rec;
exit when c_hist%notfound;
dbms_output.put_line('appointment:'||v_rec.rid||'|date:'||to_char(v_rec.rdate,'dd-mon-yyyy')||'|diagnosis:'||v_rec.diag);

if v_rec.presid is not null then
begin
select 'receipt:'||medicine_id||',dosage:'||dosage
into v_med
from prescriptions 
where prescription_id = v_rec.presid;
dbms_output.put_line(v_med);
exception
when no_data_found then
null; 
end;
end if;
end loop;
close c_hist;
exception
when no_data_found then
dbms_output.put_line('error: patient'||pid||'not found.');
when others then
if c_hist%isopen then
close c_hist;
end if;
dbms_output.put_line('error:'||sqlerrm);
end;


--cursor and record 5--
declare
cursor cur is
select d.doctor_id,d.full_name, nvl(sum(pm.amount),0) income
 from doctors d
 left join appointments a on d.doctor_id=a.doctor_id
 left join payments pm on a.appointment_id=pm.appointment_id
 group by d.doctor_id,d.full_name;
r cur%rowtype;
begin
 open cur;
   loop
   fetch cur into r;
   exit when cur%notfound;
   dbms_output.put_line(r.full_name||' earned: '||r.income||' ₸' );
   end loop;
   close cur;
end;


--collection--
declare
type t_medicine is table of varchar2(200);
meds t_medicine;
cursor cuappointments is
select appointment_id, appointment_date
from appointments
where patient_id = 10
order by appointment_date;
rec_app cur_appointments%rowtype;
begin
open cur_appointments;
loop
fetch cur_appointments into rec_app;
exit when cur_appointments%notfound;

select
case medicine_id
when 123 then 'paracetamol'
when 124 then 'ibuprofen'
when 125 then 'amoxicillin'
else 'unknown medicine'
end
|| ' (' || dosage || ', ' || duration_days || ' days)'
bulk collect into meds
from prescriptions
where appointment_id = rec_app.appointment_id
order by medicine_id;

dbms_output.put_line('appointment id: ' || rec_app.appointment_id ||', date: ' || to_char(rec_app.appointment_date, 'dd-mm-yyyy'));

if meds.count = 0 then
dbms_output.put_line('no medicines assigned.');
else
for i in 1..meds.count loop
dbms_output.put_line('  ' || i || '. ' || meds(i));
end loop;
end if;

dbms_output.put_line('');
end loop;
close cur_appointments;
end;

--package and exception 1--
create or replace package reminder_scheduler is
procedure send_appointment_reminder;
procedure send_prescription_alert;
procedure schedule_recall_checkup;
end reminder_scheduler;



create or replace package body reminder_scheduler is


procedure send_appointment_reminder is
begin
for appt_rec in (
select a.appointment_id, a.appointment_date, a.appointment_time, p.patient_id, p.first_name, p.last_name, p.phone, p.email
from appointments a
join patients p on p.patient_id = a.patient_id
where a.status = 'Scheduled'
and a.appointment_date = trunc(sysdate) + 1
) loop
dbms_output.put_line('[24h reminder] appt ' || appt_rec.appointment_id ||
' for patient ' || appt_rec.first_name || ' ' || appt_rec.last_name ||
' on ' || to_char(appt_rec.appointment_date, 'yyyy-mm-dd') ||
' at ' || appt_rec.appointment_time ||
' | phone: ' || appt_rec.phone || ' | email: ' || appt_rec.email
);
end loop;
for appt_rec2 in (
select a.appointment_id, a.appointment_date, a.appointment_time, p.patient_id, p.first_name, p.last_name, p.phone, p.email
from appointments a
join patients p on p.patient_id = a.patient_id
where a.status = 'Scheduled'
and a.appointment_date = trunc(sysdate)
and a.appointment_time = to_char(sysdate + 2/24, 'hh24:mi')
) loop
dbms_output.put_line('[2h reminder] appt ' || appt_rec2.appointment_id ||
' for patient ' || appt_rec2.first_name || ' ' || appt_rec2.last_name ||
' today at ' || appt_rec2.appointment_time ||
' | phone: ' || appt_rec2.phone || ' | email: ' || appt_rec2.email
);
end loop;
end send_appointment_reminder;


procedure send_prescription_alert is
begin
for presc_rec in (
select pr.prescription_id, pr.duration_days, a.appointment_date, p.patient_id, p.first_name, p.last_name, p.phone, p.email
from prescriptions pr
join appointments a on a.appointment_id = pr.appointment_id
join patients p on p.patient_id = a.patient_id
where a.appointment_date + pr.duration_days = trunc(sysdate) + 1
) loop
dbms_output.put_line(
'[prescription alert] prescription ' || presc_rec.prescription_id ||
' for patient ' || presc_rec.first_name || ' ' || presc_rec.last_name ||
' ends on ' ||
to_char(presc_rec.appointment_date + presc_rec.duration_days, 'yyyy-mm-dd') ||
' | phone: ' || presc_rec.phone || ' | email: ' || presc_rec.email
);
end loop;
end send_prescription_alert;

procedure schedule_recall_checkup is
begin
for recall_rec in (
select mr.patient_id, p.first_name, p.last_name, p.phone, p.email,
max(mr.record_date) as last_visit
from medical_records mr
join patients p on p.patient_id = mr.patient_id
group by mr.patient_id, p.first_name, p.last_name, p.phone, p.email
having max(mr.record_date) <= add_months(trunc(sysdate), -6)
and not exists (
select 1
from appointments a
where a.patient_id = mr.patient_id
and a.status = 'Scheduled'
and a.appointment_date > sysdate
)
) loop
dbms_output.put_line(
'[recall checkup] patient ' || recall_rec.first_name || ' ' || recall_rec.last_name ||
' last visited on ' || to_char(recall_rec.last_visit, 'yyyy-mm-dd') ||
'. suggest scheduling a follow-up. ' ||
'phone: ' || recall_rec.phone || ' | email: ' || recall_rec.email
);
end loop;
end schedule_recall_checkup;
end reminder_scheduler;


--package and exception 2--
create or replace package reports_generator is
type t_report_row is record(metric_name varchar2(100), metric_value number);
type t_report_table is table of t_report_row;
function get_doctor_performance(p_doctor_id number, p_date_from date, p_date_to date) return t_report_table;
function get_utilization_rate(p_kind varchar2, p_id number, p_month date) return number;
procedure create_daily_summary;
end reports_generator;

create or replace package body reports_generator is

function get_doctor_performance(p_doctor_id number, p_date_from date, p_date_to date) return t_report_table is
res_tab t_report_table := t_report_table();
done_cnt number;
cancel_cnt number;
avg_dur number;
begin
select count(*) into done_cnt
from appointments a
where a.doctor_id = p_doctor_id
  and a.appointment_date between p_date_from and p_date_to
  and a.status = 'Completed';
select count(*) into cancel_cnt
from appointments a
where a.doctor_id = p_doctor_id
  and a.appointment_date between p_date_from and p_date_to
  and a.status = 'Canceled';
select avg(s.duration) into avg_dur
from appointments a
join services s on s.service_id = a.service_id
where a.doctor_id = p_doctor_id
  and a.appointment_date between p_date_from and p_date_to
  and a.status = 'Completed';
res_tab.extend(3);
res_tab(1).metric_name  := 'done_count';
res_tab(1).metric_value := nvl(done_cnt,0);
res_tab(2).metric_name  := 'cancel_count';
res_tab(2).metric_value := nvl(cancel_cnt,0);
res_tab(3).metric_name  := 'avg_duration';
res_tab(3).metric_value := nvl(avg_dur,0);
return res_tab;
end get_doctor_performance;


function get_utilization_rate(p_kind varchar2, p_id number, p_month date) return number is
rate_val number;
used_cnt number;
all_cnt number;
d_start date := trunc(p_month,'mm');
d_end   date := add_months(trunc(p_month,'mm'),1);
begin
if lower(p_kind) = 'room' then
  select count(*) into used_cnt
  from appointments a
  where a.room_id = p_id
    and a.appointment_date >= d_start
    and a.appointment_date < d_end
    and a.status in ('Scheduled','Completed');
  select count(*) into all_cnt
  from appointments a
  where a.appointment_date >= d_start
    and a.appointment_date < d_end
    and a.status in ('Scheduled','Completed');
elsif lower(p_kind) = 'service' then
  select count(*) into used_cnt
  from appointments a
  where a.service_id = p_id
    and a.appointment_date >= d_start
    and a.appointment_date < d_end
    and a.status in ('Scheduled','Completed');
  select count(*) into all_cnt
  from appointments a
  where a.appointment_date >= d_start
    and a.appointment_date < d_end
    and a.status in ('Scheduled','Completed');
else
  return null;
end if;
if all_cnt = 0 then
  rate_val := 0;
else
  rate_val := (used_cnt / all_cnt) * 100;
end if;
return rate_val;
end get_utilization_rate;


procedure create_daily_summary is
d_today date := trunc(sysdate);
total_cnt number;
plan_cnt number;
cancel_cnt number;
expected_sum number;
begin
select count(*) into total_cnt
from appointments a
where trunc(a.appointment_date) = d_today;
select count(*) into plan_cnt
from appointments a
where trunc(a.appointment_date) = d_today
  and a.status = 'Scheduled';
select count(*) into cancel_cnt
from appointments a
where trunc(a.appointment_date) = d_today
  and a.status = 'Canceled';
select nvl(sum(s.price),0) into expected_sum
from appointments a
join services s on s.service_id = a.service_id
where trunc(a.appointment_date) = d_today
  and a.status = 'Scheduled';
dbms_output.put_line('date=' || to_char(d_today,'yyyy-mm-dd') ||' total=' || total_cnt ||' planned=' || plan_cnt || ' cancelled=' || cancel_cnt ||' expected_sum=' || expected_sum);
end create_daily_summary;
end reports_generator;

--package and exception 3--
create sequence seq_payment
  start with 1
  increment by 1
  nocache
  nocycle;

create or replace package payments_billing is
function calculate_bill_amount(p_appointment_id number) return number;
procedure process_payment(p_appointment_id number, p_payment_method varchar2);
procedure update_payment_status(p_payment_id number, p_new_status varchar2);
end payments_billing;


create or replace package body payments_billing is

function calculate_bill_amount(p_appointment_id number) return number is
v_amount number;
begin
select s.price
into v_amount
from appointments a
join services s on s.service_id = a.service_id
where a.appointment_id = p_appointment_id;
return nvl(v_amount,0);
exception
when no_data_found then
return 0;
end calculate_bill_amount;

procedure process_payment(p_appointment_id number, p_payment_method varchar2) is
v_amount number;
begin
v_amount := calculate_bill_amount(p_appointment_id);
insert into payments(payment_id, appointment_id, amount, payment_date, payment_method, status)
values(seq_payment.nextval, p_appointment_id, v_amount, sysdate, p_payment_method, 'paid');
dbms_output.put_line('payment processed for appointment ' || p_appointment_id || ', amount = ' || v_amount);
exception
when others then
dbms_output.put_line('error: ' || sqlerrm);
end process_payment;

procedure update_payment_status(p_payment_id number, p_new_status varchar2) is
begin
update payments
set status = p_new_status
where payment_id = p_payment_id;
if sql%rowcount = 0 then
dbms_output.put_line('no payment found with this id');
else
dbms_output.put_line('payment status updated');
end if;
exception
when others then
dbms_output.put_line('error: ' || sqlerrm);
end update_payment_status;
end payments_billing;


--trigger 1--
create or replace trigger check_room_availability
before insert on appointments
for each row
declare
v_count number;
begin
select count(*)
into v_count
from appointments
where room_id = :new.room_id
and appointment_date = :new.appointment_date
and appointment_time = :new.appointment_time;
      
if v_count > 0 then
raise_application_error(-20048,'Room ' || :new.room_id || ' is already booked for ' || to_char(:new.appointment_date, 'yyyy-mm-dd') || ' at ' || :new.appointment_time || '.');
end if;
end;


--trigger 2--
create or replace trigger appointment_require_payment
before update of status on appointments
for each row
when (new.status = 'completed' and old.status != 'completed')
declare
v_payment_count number;
begin
select count(*)
into v_payment_count
from payments
where appointment_id = :old.appointment_id;
    
if v_payment_count = 0 then
raise_application_error(-20055, 'Payment is required before marking appointment ' || :old.appointment_id || ' as completed.');
end if;
end;



--trigger 3--
create or replace trigger prescription_no_update
before update of dosage, duration_days on prescriptions
for each row
begin
    if :old.dosage is not null and (:new.dosage != :old.dosage or :new.duration_days != :old.duration_days) then
        raise_application_error(-20061, 'prescription details (dosage/duration) cannot be updated. remove the old prescription and create a new one.');
    end if;
end;

--trigger 4--
create table deleted_records_log (log_id number primary key, record_id number, deleted_by_user varchar2(50), deleted_at date, note varchar2(255));

create sequence deleted_records_log_seq start with 1;

create or replace trigger deleted_medical_record
before delete on medical_records
for each row
begin
insert into deleted_records_log (log_id, record_id, deleted_by_user, deleted_at, note)
values (deleted_records_log_seq.nextval, 
:old.record_id, user, sysdate);
end;



--trigger 5--
create or replace trigger patient_double_booking
before insert on appointments
for each row
declare
v_count number;
begin
select count(*)
into v_count
from appointments
where patient_id = :new.patient_id
and appointment_date = :new.appointment_date
and appointment_time = :new.appointment_time;
if v_count > 0 then
raise_application_error(-20091, 'patient is already booked at this time. double booking is not allowed.');
end if;
end;