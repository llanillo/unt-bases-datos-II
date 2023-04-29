-- EJERCICIO N° 1: Tipos de datos e índices 

-- a) Indique el tipo de dato adecuado cada uno de los campos de las tablas Comentarios e Tipos_autores

-- Comentarios
-- id_comentario: int
-- id_noticia: int
-- id_autor: int
-- id_usuario: int
-- comentario: varchar(200)
-- puntaje: smallint
-- fecha: date
-- baja: boolean

-- Tipos_autores
-- id_tipo_autor: int
-- tipo: varchar(30)
-- sueldo: numeric(10, 2)

-- b) ¿Qué índice/s propone para la tabla Noticias? ¿Por qué?
-- Un índice compuesto por fecha y título porque muchas búsquedas de noticias se realizan por
-- fechas o palabras claves en el título, lo cuál proporcionaría resultados con menor cantidad de tuplas

-- c) ¿Cuál de los siguientes índices considera es más efectivo para la tabla Comentarios, 
-- (puntaje, fecha) o (fecha, puntaje)? Justifique su respuesta.

-- (fecha, puntaje) es la más efectiva de las dos debido a que el índice por fecha primero nos permitiría
-- realizar un filtro y tener menor cantidad de tuplas haciendo que la consulta sea óptima y
-- no tome tanto tiempo para su culminación. En cambio, si el índice compuesto fuera (puntaje, fecha) la
-- consulta tardaría mucho tiempo buscando comentarios con cierto puntaje ya que pueden existir muchos.

--EJERCICIO N° 2: Permisos
-- Trabaje con la base de datos de Hospital. Realice las siguientes consultas e indique qué permisos y sobre qué tablas
-- debe tener el usuario User1 para poder llevar a cabo las siguientes tareas:

-- a) Muestre el nombre, apellido y cargo de los empleados que repararon las camas de las habitaciones TRIPLES del
-- piso 5 en menos de 50 días.
select p.nombre, p.apellido, c.cargo
from persona p
         inner join empleado e on (p.id_persona = e.id_empleado)
         inner join cargo c using (id_cargo)
         inner join mantenimiento_cama mc using (id_empleado)
         inner join cama ca using (id_cama)
         inner join habitacion h using (id_habitacion)
where h.tipo like '%TRIPLE%'
  and h.piso = 5
  and mc.demora < 50;

-- persona: read
-- empleado: read
-- cargo: read
-- mantenimiento_cama: read
-- habitación: read
-- cama: read

-- b) La Dra RENATA LUISA ARAOS ESTRADA indica hoy la internación del paciente RENE ARIAS en cualquier cama
-- del piso 8 pero que sea una habitación DOBLES PRIVADA. Cargue lo necesario.

-- PRUEBAS
select *
from habitacion;
select id_cama
from cama c
         inner join habitacion h using (id_habitacion)
where c.estado like '%OK%'
  and h.piso = 8
  and h.tipo like '%DOBLES PRIVADA%';

select id_empleado
from empleado e
         inner join persona p on (p.id_persona = e.id_empleado)
where p.nombre like 'RENATA LUISA'
  and p.apellido like 'ARAOS ESTRADA';

select *
from persona
where nombre like '%RENE%'
  and apellido like '%ARIAS%';
-- PRUEBAS

insert into internacion
values ((select id_persona from persona p where p.nombre like '%RENE' and p.apellido like '%ARIAS%' limit 1),
        (select id_cama
         from cama c
                  inner join habitacion h using (id_habitacion)
         where c.estado like '%OK%'
           and h.piso = 8
           and h.tipo like '%DOBLES PRIVADA%'
         limit 1), CURRENT_DATE, (select id_persona
                                  from persona p
                                  where p.nombre like '%RENATA LUISA%'
                                    and p.apellido like '%ARAOS ESTRADA%'
                                  limit 1), null, null, null);

-- internación: rw
-- persona: r
-- cama: r
-- habitación: r

-- c) Aumente en un 15% el precio de la habitación más usada (la cama con más internaciones)

update habitacion
set precio = precio * 1.15
WHERE id_habitacion = (select h.id_habitacion
                       from habitacion h
                                inner join cama c using (id_habitacion)
                                inner join internacion using (id_cama)
                       group by id_habitacion
                       order by count(*) desc
                       limit 1);
-- habitación: rw
-- cama: r
-- internación: r


-- EJERCICIO N° 3: Transacciones

-- Genere una transacción por apartado, para realizar las siguientes tareas:

--a) El día de hoy el paciente JOSE ANTONIO JIMENO realizó un pago de $2017 en su factura de 02/2022.
-- Realice las operaciones necesarias.

begin;

insert into pago
values ((select id_factura
         from factura f
                  inner join paciente pa using (id_paciente)
                  inner join persona p on (p.id_persona = pa.id_paciente)
         where p.nombre like '%JOSE ANTONIO%'
           and p.apellido like '%JIMENO%'
           and f.fecha between '2022-02-01' and '2022-02-28'
         limit 1), CURRENT_DATE, 2017);

commit;

-- b) Aumente en un 20 % el precio de los estudios de GENETICA y en un 5% a todos los tipos de TOMOGRAFIA.

begin;

update estudio e
set precio = precio * 1.2
from tipo_estudio t
where e.id_tipo = t.id_tipo
  and t.tipo_estudio like '%GENETICA%';

savepoint estudio_genetica;

update estudio e
set precio = precio * 1.05
from tipo_estudio t
where e.id_tipo = t.id_tipo
  and t.tipo_estudio like '%TOMOGRAFIA%';

savepoint estudio_tomografia;

commit;

-- c) Borre a la empleada 'GONZALO, MARIA VIRGINIA'. Realice todas las acciones necesarias para poder realizar lo
-- solicitado.		

begin;

delete
from compra c using persona p
where p.id_persona =
      (select id_persona from persona p where p.nombre like '%MARIA VIRGINIA%' and p.apellido like '%GONZALO%');

savepoint delete_compra;

delete
from paciente pa using persona p
where pa.id_paciente = p.id_persona
  and p.nombre like '%MARIA VIRGINIA%'
  and p.apellido like '%GONZALO%';

savepoint delete_paciente;

delete
from internacion i using persona p
where i.ordena_internacion =
      (select id_persona from persona p where p.nombre like '%MARIA VIRGINIA%' and p.apellido like '%GONZALO%');

savepoint delete_internacion;

delete
from tratamiento t using persona p
where t.prescribe =
      (select id_persona from persona p where p.nombre like '%MARIA VIRGINIA%' and p.apellido like '%GONZALO%');

savepoint delete_tratamiento;

delete
from compra c using persona p
where c.id_empleado =
      (select id_persona from persona p where p.nombre like '%MARIA VIRGINIA%' and p.apellido like '%GONZALO%');

savepoint delete_compra;

delete
from trabajan
where id_empleado =
      (select id_persona from persona p where p.nombre like '%MARIA VIRGINIA%' and p.apellido like '%GONZALO%');

savepoint delete_trabajan;

delete
from estudio_realizado et using persona p
where et.id_empleado =
      (select id_persona from persona p where p.nombre like '%MARIA VIRGINIA%' and p.apellido like '%GONZALO%');

savepoint delete_estudio_realizado;

delete
from diagnostico d using persona p
where d.id_empleado =
      (select id_persona from persona p where p.nombre like '%MARIA VIRGINIA%' and p.apellido like '%GONZALO%');

savepoint delete_diagnostico;

delete
from consulta c using persona p
where c.id_empleado =
      (select id_persona from persona p where p.nombre like '%MARIA VIRGINIA%' and p.apellido like '%GONZALO%');

savepoint delete_consulta;

delete
from persona p
where p.nombre like '%MARIA VIRGINIA%'
  and p.apellido like '%GONZALO%';

savepoint delete_persona;

commit;