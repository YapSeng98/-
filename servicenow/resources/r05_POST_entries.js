// RESOURCE 5: POST /entries  |  Method: POST  |  Path: /entries  |  Requires Authentication: FALSE
(function process(request, response) {
    var _tok = (request.getHeader('Authorization')||'').replace('Bearer ','').trim();
    var _au = new GlideRecord('x_887486_love_app_u_love_auth');
    _au.addQuery('u_api_key', _tok);
    _au.query();
    if (!_au.next()) { response.setStatus(401); response.setBody({error:'Unauthorized'}); return; }
    var matchId = _au.getValue('u_match') || '';

    var body = request.body.data;
    var gr = new GlideRecord('x_887486_love_app_u_love_entry');
    gr.initialize();
    gr.setValue('u_char',          body.charId   || 'char1');
    gr.setValue('u_category',      body.catId    || '');
    gr.setValue('u_category_name', body.catName  || '');
    gr.setValue('u_category_pts',  parseInt(body.pts) || 0);
    gr.setValue('u_icon',          body.icon     || '');
    gr.setValue('u_points',        parseInt(body.pts) || 0);
    gr.setValue('u_note',          body.desc     || '');
    gr.setValue('u_month',         body.month    || '');
    gr.setValue('u_date',          body.date     || new GlideDateTime().getLocalDate());
    if (matchId) gr.setValue('u_match', matchId);
    var sysId = gr.insert();

    response.setBody({ id: sysId, success: true });
    response.setStatus(201);
})(request, response);
