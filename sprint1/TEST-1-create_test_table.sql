create sequence test_id_seq;

create table test(
  id bigint not null default nextval('test_id_seq') primary key,
  content text not null unique
);
