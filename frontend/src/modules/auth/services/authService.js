import http from '../../../shared/utils/http.js'

export default {
  login(username, password) {
    return http.post('/auth/login/', { username, password })
  },
  logout(refreshToken) {
    return http.post('/auth/logout/', { refresh: refreshToken })
  },
  me() {
    return http.get('/auth/me/')
  },
}
