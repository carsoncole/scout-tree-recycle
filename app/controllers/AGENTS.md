# Controllers

## The Rails Way

- RESTful, resource-oriented controllers
- Skinny controllers: delegate business logic to models and services
- One controller per resource; standard REST actions (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`)
- Version API controllers under `Api::V1` and expose them at `/api/v1`
