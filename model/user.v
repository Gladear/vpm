module model

import rand

const (
	random = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890'
)

pub struct User {
pub:
	id int
	random_id string
	name string
}

fn random_string(len int) string {
	mut buf := []rune{ len: len, init: `0` }
	for i := 0; i < len; i++ {
		idx := rand.intn(random.len)
		buf[i] = random[idx]
	}
	return buf.str()
}


pub fn new_user(opts User) ?User {
	return {
		opts |
		random_id: random_string(20)
	}
}
