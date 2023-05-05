-- Ejercicio nro. 2:
-- Su usuario es miembro de un grupo de administradores y tiene los permisos necesarios para realizar dicha tarea,
-- pero no tiene privilegios de SuperUser, es decir, no es los mismo que el usuario Postgres.
-- Analice la base de datos y cree los usuarios y grupos necesarios (a los usuarios y grupos anteponga su nombre
-- de usuario y un guion bajo: perezj_) para cada área del Hospital y asigne los permisos mínimos para poder llevar
-- a cabo las tareas que cada uno de ellos debe realizar. Deberá crear usuarios para realizar las siguientes tareas:

-- Informes

-- a) Mostrar datos de los pacientes, si tiene obra social, también el nombre de la misma.
drop role llanillocabrerao_grupo_informes;
create role llanillocabrerao_grupo_informes with nosuperuser nocreatedb nocreaterole nocreateuser inherit login connection limit -1 valid until 'infinity';

grant
select
on obra_social, paciente, persona to llanillocabrerao_grupo_informes;

grant
select
on
table
obra_social
, paciente, persona to llanillocabrerao_grupo_informes;

-- b) Mostrar las consultas a las que asistió el paciente, también debe mostrar el medico que lo atendió, el
-- diagnóstico y el tratamiento que le suministro.
grant
select
on table consulta, diagnostico, tratamiento to llanillocabrerao_grupo_informes;

grant select (id_medicamento, nombre, presentacion) on medicamento to llanillocabrerao_grupo_informes;

-- c) Mostrar las internaciones que tuvo el paciente, debe mostrar la habitación y la cama en la que estuvo.
grant
select
on table internacion, habitacion, cama to llanillocabrerao_grupo_informes;

-- d) Mostrar los estudios que le realizaron, los equipos que se utilizaron y el profesional que le realizo el
-- estudio.
grant
select
on estudio_realizado, equipo, to llanillocabrerao_grupo_informes;

grant select (id_estudio, nombre) on estudio to llanillocabrerao_grupo_informes;
grant select (nombre, apellido) on personas to llanillocabrerao_grupo_informes;

-- e) Mostrar datos de los empleados, horarios que cumple, las consultas y diagnósticos, estudios en los que
-- intervino.
grant
select
on empleado, turno, trabajan, diagnostico, consulta to llanillocabrerao_grupo_informes;

-- Admisión
drop role llanillocabrerao_grupo_admision;
create role llanillocabrerao_grupo_admision with nosuperuser nocreatedb nocreaterole nocreateuser inherit login connection limit -1 valid until 'infinity';

-- a) Agregar, modificar o eliminar un paciente.
grant insert, update, delete on paciente to llanillocabrerao_grupo_admision;
grant insert on persona to llanillocabrerao_grupo_admision;

-- b) Listar consultas, tratamientos, diagnósticos y estudios realizados de un determinado paciente.
grant
select
on consulta, tratamiento, diagnostico, estudio_realizado, paciente, persona to llanillocabrerao_grupo_admision;

-- c) Agregar consultas.
grant insert on consulta to llanillocabrerao_grupo_admision;

-- d) Agregar estudios realizados.
grant insert on estudio_realizado to llanillocabrerao_grupo_admision;

-- e) Listar, agregar, modificar internaciones.
grant select, insert, update on internacion to llanillocabrerao_grupo_admision;

-- RRHH
drop role llanillocabrerao_grupo_rrhh;
create role llanillocabrerao_grupo_rrhh with nosuperuser nocreatedb nocreaterole nocreateuser inherit login connection limit -1 valid until 'infinity';

-- a) Agregar, modificar o eliminar empleados.
grant insert, update, delete on empleado to llanillocabrerao_grupo_rrhh;

-- b) Modificar los datos de los empleados, especialidad, cargo, horarios que cumplen.
grant
update on empleado, persona, especialidad, cargo, trabajan, turno to llanillocabrerao_grupo_rrhh;

-- Médicos
drop role llanillocabrearao_grupo_medicos;
create role llanillocabrearao_grupo_medicos with nosuperuser nocreatedb nocreaterole nocreateuser inherit login connection limit -1 valid until 'infinity';

-- a) Agregar consultas.
grant insert on consulta to llanillocabrearao_grupo_medicos;

-- b) Agregar, modificar o eliminar tratamientos.
grant insert, update, delete on tratamiento to llanillocabrearao_grupo_medicos;

-- c) Agregar, modificar o eliminar diagnósticos.
grant insert, update, delete on diagnostico to llanillocabrearao_grupo_medicos;

-- d) Agregar, modificar o eliminar estudios realizados.
grant insert, update, delete on estudio_realizado to llanillocabrearao_grupo_medicos;

-- e) Puede realizar todas las consultas que se realizan en Informes.
grant llanillocabrerao_grupo_informes to llanillocabrearao_grupo_medicos with admin option;

-- f) Puede realizar las mismas tareas que Admisión.
grant llanillocabrerao_grupo_admision to llanillocabrearao_grupo_medicos with admin option;

-- Compras
drop role llanillocabrerao_grupo_compras;
create role llanillocabrerao_grupo_compras with nosuperuser nocreaterole nocreatedb nocreateuser inherit login connection limit -1 valid until 'infinity';

-- a) Listar compras, mostrando proveedores, clasificación y laboratorio de cada insumo adquirido.
grant
select
on compra, proveedor, clasificacion, laboratorio to llanillocabrerao_grupo_compras;

-- b) Agregar laboratorios, clasificaciones, proveedores y medicamentos.
grant
insert
on
laboratorio
, clasificacion, proveedor, medicamento to llanillocabrerao_grupo_compras;

-- c) Modificar laboratorios, clasificaciones, proveedores y medicamentos.
grant
select
on laboratorio, clasificacion, proveedor, medicamento to llanillocabrerao_grupo_compras;

-- d) Eliminar laboratorios, clasificaciones, proveedores y medicamentos.
grant
delete
on laboratorio, clasificacion, proveedor, medicamento to llanillocabrerao_grupo_compras;

-- Facturación
drop role llanillocabrerao_grupo_facturacion;
create role llanillocabrerao_grupo_facturacion with nosuperuser nocreateuser nocreatedb nocreaterole inherit login connection limit -1 valid until 'infinity';

-- a) Listar las facturas, mostrando los pacientes.
grant
select
on factura, paciente, persona to llanillocabrerao_grupo_facturacion;

-- b) Agregar, modificar y eliminar facturas.
grant insert, update, delete on factura to llanillocabrerao_grupo_facturacion;

-- c) Listar los pagos, mostrando el paciente.
grant
select
on pago, paciente, persona to llanillocabrerao_grupo_facturacion;

-- d) Agregar modificar y eliminar pagos.
grant insert, update, delete on pago to llanillocabrerao_grupo_facturacion;

-- Mantenimiento
drop role llanillocabrerao_grupo_mantenimiento;
create role llanillocabrerao_grupo_mantenimiento with nosuperuser nocreateuser nocreatedb nocreaterole inherit login connection limit -1 valid until 'infinity';

-- a) Listar los equipos y el estado de los mismos.
grant
select
on equipo, mantenimiento_equipo to llanillocabrerao_grupo_mantenimiento;

-- b) Listar las camas y el estado de las mismas.
grant
select
on cama, mantenimiento_cama to llanillocabrerao_grupo_mantenimiento;

-- c) Agregar nuevos equipos.
grant insert on equipo to llanillocabrerao_grupo_mantenimiento;

-- d) Agregar nuevas camas.
grant insert on cama to llanillocabrerao_grupo_mantenimiento;

-- Sistemas
drop role llanillocabrerao_grupo_sistemas;
create role llanillocabrerao_grupo_sistemas with nosuperuser nocreaterole nocreatedb nocreateuser inherit login connection limit -1 valid until 'infinity';

-- a) Agregar, modificar o eliminar estudios.
grant insert, update, delete on estudio to llanillocabrerao_grupo_sistemas;

-- b) Agregar, modificar o eliminar cargos.
grant insert, update, delete on cargo to llanillocabrerao_grupo_sistemas;

-- c) Agregar, modificar o eliminar especialidades.
grant insert, update, delete on especialidad to llanillocabrerao_grupo_sistemas;

-- d) Agregar, modificar o eliminar tipos de estudios.
grant insert, update, delete on tipo_estudio to llanillocabrerao_grupo_sistemas;

-- e) Agregar, modificar o eliminar consultorios.
grant insert, update, delete on consultorio to llanillocabrerao_grupo_sistemas;

-- f) Agregar, modificar o eliminar obras sociales.
grant insert, update, delete on obra_social to llanillocabrerao_grupo_sistemas;

-- g) Agregar, modificar o eliminar turnos.
grant insert, update, delete on turno to llanillocabrerao_grupo_sistemas;

-- h) Listar todas las tablas antes mencionadas.
grant
select
on estudio, cargo, especialidad, tipo_estudio, consultorio, obra_social, turno to llanillocabrerao_grupo_sistemas;

-- Ejercicio nro. 3:
-- Con su usuario realice las siguientes consultas.
--
-- a) Muestre el nombre, apellido y la obra social de todos los pacientes.
select pe.nombre, pe.apellido, obra_social
from persona pe
         inner join paciente pa on pe.id_persona = pa.id_paciente
         inner join obra_social using (id_obra_social);

-- b) Liste el nombre, apellido, cargo, especialidad y sueldo de todos los empleados.
select pa.nombre, pa.apellido, c.cargo, e.especialidad, e.sueldo
from persona pa
         inner join empleado e on pa.id_persona = e.id_empleado
         inner join especialidad e using (id_especialidad)
         inner join cargo c using (id_cargo);

-- c) Muestre el nombre, apellido, fecha de internación de todos los pacientes que hayan sido dados de alta
-- entre 01/01/2019 y 31/12/2021.
select pa.nombre, pa.apellido, i.fecha_inicio
from persona pa
         inner join paciente p on pa.id_persona = p.id_paciente
         inner join internacion i using (id_paciente)
where i.fecha_alta between '2019-01-01' and '2021-12-31';

-- d) Liste el apellido y nombre de los pacientes, número, fecha y monto de las facturas que fueron pagas en
-- su totalidad.
select pa.apellido, pa.nombre, f.id_factura as numero, f.fecha, f.monto
from persona pa
         inner join paciente pe on pa.id_persona = pe.id_paciente
         inner join factura f using (id_paciente)
where pagada = 't';

-- e) Muestre el nombre, apellido de todos los empleados que diagnosticaron “Asma”, también muestre la
-- fecha de diagnóstico.
select pa.nombre, pa.apellido, d.fecha
from persona pa
         inner join empleado e on pa.id_persona = e.id_empleado
         inner join diagnostico d using (id_empleado)
         inner join patologia p using (id_patologia)
where p.nombre like '%Asma%';

-- Ejercicio nro. 4:
-- Con el usuario indicado realice las siguientes consultas (realice el código SQL e indique con cual usuario la pudo
-- realizar).
--
-- a) Mostrar todas las consultas realizadas después del ’01-01-2021’.
select c.hora, c.fecha, c.resultado
from consulta c
where c.fecha > '2021-01-01';

-- b) Mostrar los tratamientos cuyo número de dosis sea mayor que 2. Debe mostrar el nombre del paciente al
-- quien le prescribieron el tratamiento.
select pe.nombre, pe.apellido, t.nombre, t.descripcion, t.dosis
from tratamiento t
         inner join paciente pa using (id_paciente)
         inner join persona pe on pa.id_paciente = pe.id_persona
where t.dosis > 2;
-- Se puede realizar con informes, admision y medicos

-- c) Muestre todas las facturas emitidas después del ’30-06-2021’.
select f.fecha, f.hora, f.monto, f.pagada, f.saldo
from factura f
where f.fecha > '2021-06-30';
-- Se puede realizar con facturacion

-- d) Mostrar todas las facturas que han sido pagadas parcialmente.
select f.fecha, f.hora, f.monto, f.pagada, f.saldo
from factura f
where f.saldo < f.monto;
-- Se puede hacer con facturacion

-- e) Listar los medicamentos que fueron recetados posterior a ’02-05-2020’, mostrando a que laboratorio y
-- clasificación pertenecen.
select m.id_medicamento, m.nombre, m.presentacion, l.laboratorio, c.clasificacion
from medicamento m
         inner join laboratorio l using (id_laboratorio)
         inner join tratamiento t using (id_medicamento)
         inner join clasificacion c using (id_clasificacion)
where t.fecha_indicacion > '2020-05-2';
-- Se puede hacer con compras

-- f) Mostrar la historia clínica del paciente ‘CARLOS ALBERTO MARINARO‘ (todas las consultas, tratamientos,
-- estudios, internaciones, ordenados por fecha).
select pe.nombre,
       pe.apellido,
       c.hora,
       c.resultado,
       t.fecha_indicacion,
       t.nombre,
       t.descripcion,
       e.nombre,
       e.descripcion,
       i.fecha_alta,
       i.costo
from persona pe
         inner join paciente pa on pe.id_persona = pa.id_paciente
         inner join estudio_realizado using (id_paciente)
         inner join tratamiento t using (id_paciente)
         inner join internacion i using (id_paciente)
         inner join estudio e using (id_estudio)
         inner join consulta c using (id_paciente)
where pe.nombre like '%CARLOS ALBERTO%'
  and pe.apellido like '%MARINARO%';
-- Se puede hacer con medicos

-- g) Mostrar todos los pagos realizados por ‘RODOLFO JULIO URTUBEY’.
select p.fecha, p.monto
from pago p
         inner join factura f using (id_factura)
         inner join paciente pa using (id_paciente)
         inner join persona pe
                    on pa.id_paciente = pe.id_persona
where pe.nombre like '%RODOLFO JULIO%'
  and pe.apellido like '%URTUBEY%';
--Se puede hacer con facturacion

-- h) Mostrar todas las consultas que atendió el medico ‘LAURA LEONOR ESTRADA’.
select c.fecha, c.hora, c.resultado
from consulta c
         inner join empleado using (id_empleado)
         inner join persona pe on empleado.id_empleado = pe.id_persona
where pe.nombre like '%LAURA LEONOR%'
  and pe.apellido like '%ESTRADA%';
-- Se puede hacer con informes, admision y medicos

-- i) Listar todas las camas que están fuera de servicio.
select c.id_cama, c.tipo, c.estado
from cama c
where c.estado like '%FUERA DE SERVICIO%';
-- Se puede hacer con mantenimiento

-- j) Listar todos los equipos que están en mantenimiento.
select e.id_equipo, e.nombre, e.marca
from equipo e
         inner join mantenimiento_equipo using (id_equipo);
-- Se puede hacer con mantenimiento

-- k) Muestre todas las compras realizadas en el 2020 indicando el medicamento, el proveedor y el empleado
-- que realizo la compra.
select m.id_medicamento,
       m.nombre,
       m.presentacion,
       p.id_proveedor,
       p.proveedor,
       p.direccion,
       pe.nombre,
       pe.apellido,
       c.fecha,
       c.precio_unitario,
       c.cantidad
from compra c
         inner join proveedor p using (id_proveedor)
         inner join medicamento m using (id_medicamento)
         inner join empleado e using (id_empleado)
         inner join persona pe on e.id_empleado = pe.id_persona
where DATE_PART('year', c.fecha) = 2020;
-- Se puede hacer con compras

-- l) Agregar el registro en la tabla compras (1824, 23, ’10-11-2022’, 634, 1443.42, 75).
insert into compra (id_medicamento, id_proveedor, fecha, id_empleado, precio_unitario, cantidad)
values (1824, 23, '10-11-2022', 634, 1443.42, 75);
-- Se puede hacer con compras

-- m) Agregar el registro en la tabla proveedores (33, "DISTRI MED S.A.”, “AV. COLON 1291", "2411617").
insert into proveedor (id_proveedor, proveedor, direccion, telefono)
values (33, 'DISTRI MED S.A', 'AV. COLON 1291', '2411617');
-- Se puede hacer con compras

-- n) Agregar el registro en la tabla laboratorios (206, "INDUSTFARM”, “MIGUEL LINCE 124 ", "2416411").
insert into laboratorio (id_laboratorio, laboratorio, direccion, telefono)
values (206, 'INDUSTFARM', 'MIGUEL LINCE 124', '2416411');
-- Se puede hacer con compras

-- o) Modificar el teléfono del proveedor "DISTRI MED S.A.”, por el 22244433.
update proveedor
set telefono = '22244433'
where proveedor like '%DISTRI MED S.A%';
-- Se puede hacer con compras

-- p) Modificar el horario de trabajo de ‘FABIOLA MELISA PACHECO’ del sábado a la mañana al sábado a la
-- noche.
update turno t
set descripcion = 'Sabados De 9:00 A 20:00' from empleado e
         inner join persona pe
on e.id_empleado = pe.id_persona
where pe.nombre like '%FABIOLA MELISA%'
  and pe.apellido like '%PACHECO%';
-- Se puede hacer con RRHH

-- q) Eliminar el laboratorio “BAYER QUIMICAS UNIDAS S.A.”
delete
from laboratorio l
where l.laboratorio like '%BAYER QUIMICAS UNIDAS S.A%';
-- Se puede hacer con compras