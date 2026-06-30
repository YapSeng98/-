// RESOURCE 23: PUT /auth/charimg  |  Method: PUT  |  Path: /auth/charimg  |  Requires Authentication: FALSE
(function process(request, response) {
    var _tok = (request.getHeader('Authorization')||'').replace('Bearer ','').trim();
    var _au = new GlideRecord('x_887486_love_app_u_love_auth');
    _au.addQuery('u_api_key', _tok);
    _au.query();
    if (!_au.next()) { response.setStatus(401); response.setBody({error:'Unauthorized'}); return; }

    var body    = request.body && request.body.data;
    var imgData = body ? (body.charImg || '') : '';

    _au.setValue('u_profile_picture', imgData);
    _au.update();

    response.setBody({ success: true });
})(request, response);
