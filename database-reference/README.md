# Database

The canonical MySQL data model is `../api/prisma/schema.prisma`. The reproducible initial migration is `../api/prisma/migrations/0_init/migration.sql`.

Do not maintain a second hand-written schema here. Schema changes must be represented as reviewed Prisma migrations and verified against a fresh MySQL 8 database before deployment.

