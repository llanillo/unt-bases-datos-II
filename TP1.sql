-- 1) Muestre el id, nombre, apellido y dni de los pacientes que tienen obra social. 113435
select p.id_paciente, per.nombre, per.apellido, per.dni
from paciente p
         inner join obra_social ob using (id_obra_social)
         inner join persona per on p.id_paciente = per.id_persona;

-- 2) Liste todos los pacientes con obra social que fueron atendidos en los consultorios 'CARDIOLOGIA' o
-- 'NEUMONOLOGIA'. Debe mostrar el nombre, apellido, dni y nombre de la obra social. 33716
select pa.id_paciente, per.nombre, per.apellido, per.dni
from paciente pa
         inner join
     persona per on pa.id_paciente = per.id_persona
         inner join obra_social ob using (id_obra_social)
         inner join consulta using (id_paciente)
         inner join consultorio con using (id_consultorio)
where con.nombre in ('NEOMONOLOGIA', 'CARDIOLOGIA');

select pa.id_paciente, per.nombre, per.apellido, per.dni
from paciente pa
         inner join
     persona per on pa.id_paciente = per.id_persona
         inner join consulta using (id_paciente)
         inner join consultorio con using (id_consultorio)
where con.nombre in ('NEOMONOLOGIA', 'CARDIOLOGIA')
  and pa.id_obra_social is not null;

--3) Liste el id, nombre, apellido y sueldo de los empleados, como así también su cargo y especialidad.
--Ordenado alfabéticamente por cargo, luego por especialidad y en último término por sueldo de mayor a
--menor.- 996

select p.id_persona, p.nombre, p.apellido, em.sueldo, car.cargo, esp.especialidad
from persona p
         inner join
     empleado em on p.id_persona = em.id_empleado
         inner join cargo car using (id_cargo)
         inner join especialidad esp
                    using (id_especialidad)
order by car.cargo, esp.especialidad, em.sueldo desc;

-- 4) Encuentre el empleado, cargo y turno de todos los empleados cuyo cargo sea AUXILIAR y el turno de
-- trabajo aún se encuentre vigente. 170
select p.id_persona, p.nombre, p.apellido, c.cargo, t.turno
from persona p
         inner join empleado e on p.id_persona = e.id_empleado
         inner join trabajan tr using (id_empleado)
         inner join turno t using (id_turno)
         inner join cargo c using (id_cargo)
where c.cargo like '%AUXILIAR%'
  and tr.fin is not null;

-- 5) Muestre la cantidad de compras realizadas por los empleados de la especialidad SIN ESPECIALIDAD
--MEDICA. Debe mostrar el nombre del empleado, el cargo que tiene y la cantidad de compras, ordenado
-- por cantidad de mayor a menor. 504
select p.nombre, c.cargo, count(*) as cantidad_compras, es.especialidad
from persona p
         inner join empleado e
                    on p.id_persona = e.id_empleado
         inner join especialidad es using (id_especialidad)
         inner join cargo c using (id_cargo)
         inner join compra com using (id_empleado)
where es.especialidad = 'SIN ESPECIALIDAD MEDICA'
group by p.id_persona, c.cargo, es.especialidad
order by cantidad_compras desc;

-- 6) Muestre los pacientes que tienen obra social, que fueron internados en septiembre del 2019, en el 7mo y
-- 8vo piso. Ordenados por la fecha de internación de mayor a menor. 2158
select p.id_persona, p.nombre, int.fecha_inicio, ha.piso
from persona p
         inner join paciente pa on p.id_persona = pa.id_paciente
         inner join internacion int using (id_paciente)
         inner join cama using (id_cama)
         inner join habitacion ha using (id_habitacion)
where pa.id_obra_social is not null
  and ha.piso in ('7', '8')
  and int.fecha_inicio between '2019-09-01' and '2019-09-30'
order by int.fecha_inicio desc;

-- 7) Muestre los proveedores a los que no se les compró ningún medicamento. 0
select p.proveedor
from proveedor p
where p.id_proveedor not in (select id_proveedor
                             from proveedor
                                      inner join compra c using (id_proveedor));

--8) Liste los medicamentos que no fueron prescriptos nunca. 3
select m.nombre
from medicamento m
where id_medicamento not in (select id_medicamento
                             from medicamento
                                      inner join tratamiento using (id_medicamento));

-- 9) Muestre los empleados que hayan realizado más internaciones que 'DAVID MASAVEU' antes del 15/02/2019. 22
select p.nombre, count(int.id_paciente) as inter_Resto
from persona p
         inner join empleado e on p.id_persona = e.id_empleado
         inner join internacion int on int.ordena_internacion = e.id_empleado
where int.fecha_inicio < '2019-02-15'
group by p.nombre
having count(int.id_paciente) > (select count(int.id_paciente) as inter_MASAVEU
                                 from persona p
                                          inner join empleado e on p.id_persona = e.id_empleado
                                          inner join internacion int on int.ordena_internacion = e.id_empleado
                                 where p.nombre = 'DAVID'
                                   and p.apellido = 'MASAVEU'
                                   and int.fecha_inicio < '2019-02-15');

-- 10) Muestre los pacientes a los que les hayan facturado más que ‘LAURA MONICA JABALOYES’ desde el 15/05/2022 a la fecha. 554
select p.nombre, p.apellido, sum(fa.monto)
from persona p
         inner join paciente pa on id_persona = id_paciente
         inner join factura fa using (id_paciente)
where fa.fecha > '2022-05-15'
group by p.nombre, p.apellido
having sum(fa.monto) > (select sum(fa.monto)
                        from persona p
                                 inner join paciente pa on id_persona = id_paciente
                                 inner join factura fa using (id_paciente)
                        where p.nombre = 'LAURA MONICA'
                          and p.apellido = 'JABALOYES'
                          and fa.fecha > '2022-05-15'
                        group by p.nombre)
order by sum(fa.monto);

-- 11) Liste todos los empleados que no hayan comprado medicamentos del proveedor ‘ARABESA’ entre el
-- 01/02/2018 y el 10/03/2018. Ordénelos alfabéticamente.
select per.id_persona, per.nombre, per.apellido
from persona per
         inner join empleado empl on per.id_persona = empl.id_empleado
         inner join compra com using (id_empleado)
         inner join proveedor pro using (id_proveedor)
where pro.proveedor like '%ARABESA'
  and com.fecha between '2018-02-01' and '2018-03-10'
  and per.id_persona
    not in (select empl2.id_empleado
            from persona
                     inner join empleado empl2 on persona.id_persona = empl2.id_empleado
                     inner join compra com2 on empl2.id_empleado = com2.id_empleado
                     inner join proveedor pro2 on com2.id_proveedor = pro2.id_proveedor
            where pro2.proveedor like '%ARABESA%'
              and com2.fecha between '2018-02-01' and '2018-03-10')
order by per.nombre;

-- 12) Muestre los 5 medicamentos más recetados y el laboratorio al que pertenecen.
select med.id_medicamento,
       med.nombre,
       med.precio,
       lab.laboratorio,
       count(id_medicamento) as cantidad_veces_recetada
from medicamento med
         inner join tratamiento tra using (id_medicamento)
         inner join laboratorio lab using (id_laboratorio)
group by med.id_medicamento, med.nombre, med.precio, lab.laboratorio
order by cantidad_veces_recetada desc
limit 5;


-- 13) Muestre (en una sola consulta) el id, fecha de ingreso y estado de todas las camas y equipos que aún no
-- fueron reparadas.
select int.fecha_alta,
       ca.id_cama,
       ca.tipo,
       ca.estado,
       eq.id_equipo,
       eq.nombre,
       eq.marca,
       mac.estado,
       maq.estado
from empleado em
         inner join internacion int on int.ordena_internacion = em.id_empleado
         inner join cama ca using (id_cama)
         inner join mantenimiento_cama mac using (id_cama)
         inner join mantenimiento_equipo maq on maq.id_empleado = em.id_empleado
         inner join equipo eq using (id_equipo)
where mac.estado not like '%reparado%'
  and maq.estado not like '%reparado%';

-- 14) Modifique el precio, aumentando un 5%, a los medicamentos cuyo laboratorio sea ‘LABOSINRATO’ y la
-- clasificación sea ‘APARATO DIGESTIVO’ o ‘VENDAS’.
update medicamento as med
set precio = precio * 1.05
from laboratorio lab
         inner join clasificacion cla on med.id_clasificacion = cla.id_clasificacion
where lab.laboratorio like '%LABOSINRATO%' and cla.clasificacion like '%APARATO DIGESTIVO'
   or '%VENDA;%';

-- 15) Modifique el campo estado de la tabla mantenimiento_equipo, con la palabra “baja” y en la fecha de
-- egreso ponga la fecha del sistema, de aquellos equipos que ingresaron hace más de 100 días (recalcule
-- usando la fecha de ingreso y la del sistema)
update mantenimiento_equipo set estado = 'baja', fecha_ingreso = current_date
from;

-- 16) Elimine las clasificaciones que no se usan en los medicamentos. 22 filas afectadas
delete
from clasificacion cla
where cla.id_clasificacion not in (select id_clasificacion from medicamento);

-- 17) Elimine las compras realizadas entre 01/03/2008 y 15/03/2008, de los medicamentos cuya clasificación es
-- ‘ENERGETICOS’. 1951 filas afectadas
delete
from compra using medicamento med inner join clasificacion cla using (id_clasificacion)
where fecha between '2008-03-01' and '2008-03-15'
  and cla.clasificacion like '%ENERGETICOS%';