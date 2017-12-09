devserver:
	mix phx.server
devtest:
	mix test.watch
db:
	docker run -p 5432:5432 -e POSTGRES_PASSWORD=pass1234 -e POSTGRES_DB=db postgres
db_connect:
	psql -h localhost -U postgres -d db
