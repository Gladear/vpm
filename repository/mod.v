module repository

import model
import pg

pub struct ModRepo {
	db pg.DB
}

pub fn (repo &ModRepo) create(mod model.Mod) ? {
	// Check that the mod is valid
	model.new_mod(mod) ?
	repo.db.exec_param_many('insert into modules (name, url, nr_downloads, vcs) values ($1, $2, $3, $3)',
		[mod.name, mod.url, mod.nr_downloads.str(), mod.vcs]) or {
		return error('unuable to create mod: $err')
	}
}

fn mod_from_row(row pg.Row) model.Mod {
	return model.Mod{
		name: row.vals[0]
		url: row.vals[1]
		nr_downloads: row.vals[2].int()
		vcs: row.vals[3]
	}
}

pub fn (repo &ModRepo) find_all() []model.Mod {
	rows := repo.db.exec('select name, url, nr_downloads, vcs from modules order by nr_downloads desc') or {
		panic(err)
	}
	return rows.map(mod_from_row)
}

pub fn (repo &ModRepo) find_by_name(name string) ?model.Mod {
	rows := repo.db.exec_param('select name, url, nr_downloads from modules where name=$1',
		name) or { return error(err) }
	if rows.len == 0 {
		return error('Found no module with name "$name"')
	}
	return mod_from_row(rows[0])
}

pub fn (repo &ModRepo) inc_nr_downloads(name string) {
	repo.db.exec_param('update modules set nr_downloads=nr_downloads+1 where name=$1',
		name)
}
