-- Ejercicio 1
begin;

insert into consulta
values ((select max(id_paciente) from paciente), 253, '2023-03-23', 5, '14:14:00', 'SE DIAGNOSTICA DERMATITIS');

insert into paciente
values ((select max(id_persona) + 1 from persona), 137);

insert into persona
values ((select max(id_persona) + 1 from persona), 'ALEJANDRA', 'HERRERA', 37366992, '1992-06-20', 'SAN JUAN 258',
        '54-381-326-1780');

rollback;

commit;

-- Ejercicio 2

begin;

update medicamento me
set precio = precio * 1.02
from laboratorio lab,
     clasificacion cla
where lab.id_laboratorio = me.id_laboratorio
  and me.id_clasificacion = cla.id_clasificacion
  and cla.clasificacion like '%ANALGESICO%'
  and lab.laboratorio like '%ABBOTT LABORATORIOS%';

update medicamento me
set precio = precio * 0.965
from laboratorio lab,
     clasificacion cla
where lab.id_laboratorio = me.id_laboratorio
  and me.id_clasificacion = cla.id_clasificacion
  and cla.clasificacion like '%ANALGESICO%'
  and lab.laboratorio like '%BAYER QUIMICAS UNIDAS S.A%';

update medicamento me
set precio = precio * 1.08
from laboratorio lab,
     clasificacion cla
where lab.id_laboratorio = me.id_laboratorio
  and me.id_clasificacion = cla.id_clasificacion
  and cla.clasificacion like '%ANALGESICO%'
  and lab.laboratorio like '%COFANA (CONSORCIO FARMACEUTICO NACIONAL)%';

update medicamento me
set precio = precio * 0.96
from laboratorio lab,
     clasificacion cla
where lab.id_laboratorio = me.id_laboratorio
  and me.id_clasificacion = cla.id_clasificacion
  and cla.clasificacion like '%ANALGESICO%'
  and lab.laboratorio like '%FARPASA FARMACEUTICA DEL PACIFICO%';

update medicamento me
set precio = precio * 0.898
from laboratorio lab,
     clasificacion cla
where lab.id_laboratorio = me.id_laboratorio
  and me.id_clasificacion = cla.id_clasificacion
  and cla.clasificacion like '%ANALGESICO%'
  and lab.laboratorio like '%RHONE POULENC ONCOLOGICOS%';

update medicamento me
set precio = precio * 1.055
from laboratorio lab,
     clasificacion cla
where lab.id_laboratorio = me.id_laboratorio
  and me.id_clasificacion = cla.id_clasificacion
  and cla.clasificacion like '%ANALGESICO%'
  and lab.laboratorio like '%ROEMMERS%';

update medicamento me
set precio = precio * 1.07
from laboratorio lab,
     clasificacion cla
where lab.id_laboratorio = me.id_laboratorio
  and me.id_clasificacion = cla.id_clasificacion
  and cla.clasificacion like '%ANALGESICO%'
  and lab.laboratorio not in
      ('ABBOTT LABORATORIOS', 'BAYER QUIMICAS UNIDAS S.A', 'COFANA (CONSORCIO FARMACEUTICO NACIONAL)',
       'FARPASA FARMACEUTICA DEL PACIFICO', 'RHONE POULENC ONCOLOGICOS', 'ROEMMERS');

select precio
from medicamento
         inner join laboratorio l on medicamento.id_laboratorio = l.id_laboratorio
         inner join clasificacion c on medicamento.id_clasificacion = c.id_clasificacion
where laboratorio like '%BAYER QUIMICAS UNIDAS S.A%'
  and c.clasificacion like '%ANALGESICO%';

rollback;

commit;

-- Ejercicio 3

begin;

-- Apartado a
insert into estudio_realizado
values (175363, 24, '2023-04-01', 15, 522, 'NORMAL', 'NO SE OBSERVAN IRREGULARIDADES', 3526.00);

-- Apartado b
insert into tratamiento
values (175363, 1532, '2023-04-04', 253, 'AFRIN ADULTOS SOL', 'FRASCO X 15 CC', '1', 1821.79);

insert into tratamiento
values (175363, 1560, '2023-04-04', 253, 'NAFAZOL', 'FRASCO X 15 ML', '2', 1850.96);
insert into tratamiento
values (175363, 1522, '2023-04-04', 253, 'VIBROCIL GOTAS NAZALES', 'FRASCO X 15 CC', '2', 2500.66);

-- Apartado c
insert into internacion
values (175363, 157, '2023-04-03', 253, '2023-04-06', '11:30:00', 160000.00);

rollback;
commit;

-- Ejercicio 4
begin;

insert into factura
values ((select max(id_factura) + 1 from factura), 175363, '2023-04-06', '00:00:00', 169699.41, 'N', 169699.41);

commit;

-- Ejercicio 5

-- Apartado a
-- Persona 1: Muestra todos los campos de patología 1
-- Se ve el dato original
select *
from patologia
where id_patologia = 1;

-- Luego del update se ve la modificación de Persona 2
-- Luego del commit se sigue viendo la modificación de Persona 2
-- Nivel de aislamiento: Lectura sucia

-- Apartado b

begin isolation level repeatable read;
-- Persona 1: Muestra todos los campos de patología 1
-- Se ve el dato original
select *
from patologia
where id_patologia = 1;

-- Luego de la modificación de Persona 2, Persona 1 sigue viendo los datos originales
-- Luego del commit de Persona 2, Persona 1 sigue viendo el dato original
-- Luego del commit de Persona 1 ya se puede ver la modificación

commit;

-- Ejercicio 6

begin;

insert into mantenimiento_cama (id_cama, fecha_ingreso, estado, observacion)
values (53, '2023-04-20', 'EN REPARACION', '');

insert into mantenimiento_cama (id_cama, fecha_ingreso, estado, observacion)
values (111, '2023-04-20', 'EN REPARACION', '');

insert into mantenimiento_cama (id_cama, fecha_ingreso, estado, observacion)
values (163, '2023-04-20', 'EN REPARACION', '');

insert into mantenimiento_equipo (id_equipo, fecha_ingreso, estado, observacion)
values (12, '2023-04-20', 'EN REPARACION', '');

insert into mantenimiento_equipo (id_equipo, fecha_ingreso, estado, observacion)
values (30, '2023-04-20', 'EN REPARACION', '');

commit;

-- Ejercicio 7

begin;

insert into compras values ()

commit;

-- Ejercicio 8

begin;

delete from paciente where id = 175363;

commit;

begin;

delete from medicamento where nombre like '%SALBUTOL GOTAS%';