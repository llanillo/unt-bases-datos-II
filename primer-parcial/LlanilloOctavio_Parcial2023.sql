EJERCICIO N° 3: Transacciones
 Escriba las transacciones para realizar las tareas que se piden a continuación, recuerde usar los "puntos seguros" para facilitar la tarea.
 a)  Ingresar un nuevo empleado.

Nombre: BRUCE
Apellido: BANNER
DNI:12122211
Fecha de Nacimiento: 01-05-1962
Domicilio: MARVEL STUDIOS
Teléfono: 99999999

Especialidad: ANATOMOPATOLOGÍA
Cargo: MEDICO ANATOMOPATOLOGO
Fecha de ingreso: 04-05-2023
Sueldo: 350000.00
Fecha de baja:  --

begin;

insert into persona
values ((select max(id_persona) from persona) + 1, 'BRUCE', 'BANNER',
        12122211, '1962-05-01', 'MARVEL STUDIOS', 99999999);

savepoint alta_persona;

insert into empleado
values ((select id_persona from persona where apellido like '%BANNER%' and nombre like '%BRUCE%' limit 1),
        (select id_especialidad from especialidad where especialidad like '%ANATOMOPATOLOGÍA%' limit 1),
        (select id_cargo from cargo where cargo like '%MEDICO ANATOMOPATOLOGO%' limit 1),
        '2023-05-04', 350000.00, null);

savepoint alta_empleado;

commit;


Escriba las transacciones para realizar las tareas que se piden a continuación, recuerde usar los "puntos seguros" para facilitar la tarea.

 b) Por cuestiones estructurales se necesita eliminar la habitación 90, realice todas las operaciones necesarias para poder eliminar dicha habitación. -

-- El backup hospital_final no tiene camas asignadas a la habitación 90 por lo que el delete directo eliminaría la habitación sin errores
-- En el caso que hubieran camas en esta habitación, las camas no se deberían eliminar ya que estas podrían ser asignadas
-- a otras habitaciones por lo que se necesitara poner null en la clave foránea id_habitacion en la tabla cama de las camas
-- que pertenecieran a la habitación 90
begin;

delete from habitacion where id_habitacion = 90;

commit;
