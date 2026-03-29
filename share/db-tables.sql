CREATE TABLE "user" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "email" text,
  "password" text,
  "username" text,
  "user_root" text,
  "reg_token" text,
  "created" integer,
  "lastlogin" integer,
  "lastactivity" integer,
  "sessionips" text,
  "user_status" text,
  "data" text
  FOREIGN KEY ("user_root") REFERENCES "user_root"("id") ON DELETE CASCADE,
  CASCADE
);
CREATE INDEX "user_root_idx" ON "users" ("user_root");

CREATE TABLE "user_root" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "path" integer,
  "mount" text,
  "" text,
  --"issue_id" text,
  --"discussion_id" text,
  --"release_id" text,
  "created" integer,
  --"lastlogin" integer,
  --"lastactivity" integer,
  --"visibility" text,
  "data" text
  FOREIGN KEY ("user") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
  --FOREIGN KEY ("issue_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
  -- FOREIGN KEY ("user") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
  CASCADE
);
--CREATE INDEX "users_idx_default_return" ON "users" ("default_return");
--CREATE INDEX "users_idx_promo_id" ON "users" ("promo_id");


CREATE TABLE "repo" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "user" integer,
  "name" text,
  "directory" text,
  --"issue_id" text,
  --"discussion_id" text,
  --"release_id" text,
  "created" integer,
  --"lastlogin" integer,
  "lastactivity" integer,
  "visibility" text,
  "data" text
  FOREIGN KEY ("user") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
  --FOREIGN KEY ("issue_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
  -- FOREIGN KEY ("user") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
  CASCADE
);
--CREATE INDEX "users_idx_default_return" ON "users" ("default_return");
--CREATE INDEX "users_idx_promo_id" ON "users" ("promo_id");
