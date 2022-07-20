CREATE DATABASE sampledb;

\c sampledb

CREATE TABLE IF NOT EXISTS users (
	id serial PRIMARY KEY,
	full_name VARCHAR ( 255 ) NOT NULL,
	created_on TIMESTAMP default current_timestamp
);

CREATE TABLE IF NOT EXISTS company (
	id INTEGER NOT NULL PRIMARY KEY,
	name TEXT NOT NULL,
	age INTEGER NOT NULL,
	address CHARACTER(50),
	salary REAL,
	join_date DATE,
	notes CHARACTER VARYING(500)
);

CREATE TABLE IF NOT EXISTS company_temp (
	id INTEGER NOT NULL,
	name TEXT NOT NULL,
	age INTEGER NOT NULL,
	address CHARACTER(50),
	salary REAL,
	join_date DATE,
	notes CHARACTER VARYING(500)
);