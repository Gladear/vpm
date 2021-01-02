module main

import vweb
import pg
import json
import rand
import rand.util
import model
import repository

const (
	port = 8090
)

struct App {
	vweb.Context
pub mut:
	mods      repository.ModRepo
	users     repository.UserRepo
}

fn main() {
	seed := util.time_seed_array(2)
	rand.seed([seed[0], seed[1]])
	vweb.run<App>(port)
}

pub fn (mut app App) init_once() {
	println('pg.connect()')
	db := pg.connect(
		host: 'localhost'
		dbname: 'vpm'
		user: 'admin'
	) or {
		panic(err)
	}
	app.mods = repository.ModRepo{db}
	app.users = repository.UserRepo{db}
	// app.serve_static('/img/github.png', 'img/github.png')
}

pub fn (mut app App) init() {
}

pub fn (mut app App) index() vweb.Result {
	app.set_cookie({
		name: 'vpm'
		value: '777'
	})
	mods := app.mods.find_all()
	return $vweb.html()
}

pub fn (mut app App) reset() {
}

pub fn (mut app App) new() vweb.Result {
	cur_user := app.get_user() or {
		return app.json('401')
	}
	logged_in := cur_user.name != ''
	println('new() loggedin: $logged_in')
	return $vweb.html()
}

[post]
pub fn (mut app App) create_module() vweb.Result {
	cur_user := app.get_user() or {
		return app.json('401')
	}
	mod := model.new_mod(
		name: '${cur_user.name}.${app.form["name"]}'
		url: app.form['url']
		vcs: app.form['vcs']
	) or {
		eprintln('Unable to create mod: $err')
		return app.redirect('/')
	}
	println('CREATE mod="$mod"')
	app.mods.create(mod)
	return app.redirect('/')
}

pub fn (mut app App) mod() vweb.Result {
	name := app.get_mod_name()
	println('mod name=$name')
	mod := app.mods.find_by_name(name) or {
		return app.redirect('/')
	}
	// comments := app.find_comments(id)
	// show_form := true
	return $vweb.html()
}

pub fn (mut app App) jsmod() vweb.Result {
	name := app.req.url.replace('jsmod/', '')[1..]
	println('MOD name=$name')
	app.mods.inc_nr_downloads(name)
	mod := app.mods.find_by_name(name) or {
		return app.json('404')
	}
	return app.json(json.encode(mod))
}

// "/post/:id/:title"
pub fn (app App) get_mod_name() string {
	return app.req.url[5..]
}
