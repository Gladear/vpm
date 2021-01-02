module main

import net.http
import json
import os
import model
import vweb

const (
	client_id     = os.getenv('VPM_GITHUB_CLIENT_ID')
	client_secret = os.getenv('VPM_GITHUB_SECRET')
)

struct GitHubUser {
	login string
}

fn (mut app App) oauth_cb() vweb.Result {
	code := app.req.url.all_after('code=')
	println('code=$code')
	if code == '' {
		// TODO return internal server error
		return app.json('500')
	}
	d := 'client_id=$client_id&client_secret=$client_secret&code=$code'
	resp := http.post('https://github.com/login/oauth/access_token', d) or {
		eprintln('unable to get access token: $err')
		// TODO return internal server error
		return app.json('500')
	}
	println('resp text=' + resp.text)
	token := resp.text.find_between('access_token=', '&')
	println('token =$token')
	user_js := http.fetch('https://api.github.com/user?access_token=$token', {
		method: .get
		headers: {
			'User-Agent': 'V http client'
		}
	}) or {
		eprintln('unable to get user from token: $err')
		return app.json('500')
	}
	gh_user := json.decode(GitHubUser, user_js.text) or {
		println('cant decode: $err')
		return app.json('500')
	}
	login := gh_user.login.replace(' ', '')
	if login.len < 2 {
		return app.redirect('/new')
	}
	println('login=$login')
	new_user := model.new_user(name: login) or {
		eprintln('error creating user: $err')
		return app.json('500')
	}
	app.users.create(new_user) or {
		eprintln('error inserting user in database: $err')
		return app.json('500')
	}
	// Fetch the new or already existing user and set cookies
	user := app.users.find_by_name(login) or {
		eprintln('unable to retrieve user id: $err')
		return app.json('500')
	}
	app.set_cookie({
		name: 'id'
		value: user.id.str()
	})
	app.set_cookie({
		name: 'q'
		value: user.random_id
	})
	println('redirecting to /new')
	return app.redirect('/new')
}

fn (mut app App) get_user() ?model.User {
	raw_id := app.get_cookie('id') or {
		return error('failed to id cookie')
	}
	id := raw_id.int()
	q_cookie := app.get_cookie('q') or {
		return error('failed to get q cookie.')
	}
	random_id := q_cookie.trim_space()
	println('auth sid="$raw_id" id=$id len ="$random_id.len" qq="$random_id" !!!')
	if id == 0 {
		return error('invalid auth sid')
	}
	return app.users.find_by_id(id, random_id)
}
