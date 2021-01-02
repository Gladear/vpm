module repository

import model
import pg

pub struct UserRepo {
	db pg.DB
}

pub fn (repo &UserRepo) create(user model.User) ? {
	if user.id != 0 {
		return error('user already exists')
	}
	repo.db.exec_param2('insert into users (name, random_id) values ($1, $2)', user.name, user.random_id) or {
		return error('error while creating user: $err')
	}
}

fn user_from_row(row pg.Row) model.User {
	return model.User{
		id: row.vals[0].int()
		random_id: row.vals[1]
		name: row.vals[2]
	}
}

pub fn (repo &UserRepo) find_by_id(user_id int, random_id string) ?model.User {
	users := repo.db.exec_param('select id, random_id, name from users where id=$user_id and random_id=$1',
		random_id) ?
	if users.len == 0 {
		return error('no such user "$user_id" r="$random_id"')
	}
	return user_from_row(users[0])
}

pub fn (repo &UserRepo) find_by_name(name string) ?model.User {
	users := repo.db.exec_param('select id, random_id, name from users where name=$1', name) ?
	if users.len == 0 {
		return error('no such user "$name"')
	}
	return user_from_row(users[0])
}
