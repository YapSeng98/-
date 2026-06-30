// RESOURCE 12: POST /categories  |  Method: POST  |  Path: /categories  |  Requires Authentication: FALSE
(function process(request, response) {
    var _tok = (request.getHeader('Authorization')||'').replace('Bearer ','').trim();
    var _au = new GlideRecord('x_887486_love_app_u_love_auth');
    _au.addQuery('u_api_key', _tok);
    _au.query();
    if (!_au.next()) { response.setStatus(401); response.setBody({error:'Unauthorized'}); return; }
    var matchId = _au.getValue('u_match') || '';

    var body = request.body.data;
    var gr = new GlideRecord('x_887486_love_app_u_love_category');
    gr.initialize();
    gr.setValue('u_emoji',  body.icon   || '');
    gr.setValue('u_name',   body.name   || '');
    gr.setValue('u_points', parseInt(body.pts) || 0);
    gr.setValue('u_active', body.active !== false);
    if (matchId) gr.setValue('u_match', matchId);
    var sysId = gr.insert();
    response.setBody({ id: sysId, success: true });
    response.setStatus(201);
})(request, response);
