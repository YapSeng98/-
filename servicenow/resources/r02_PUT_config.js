// RESOURCE 2: PUT /config  |  Method: PUT  |  Path: /config  |  Requires Authentication: FALSE
(function process(request, response) {
    var _tok = (request.getHeader('Authorization')||'').replace('Bearer ','').trim();
    var _au = new GlideRecord('x_887486_love_app_u_love_auth');
    _au.addQuery('u_api_key', _tok);
    _au.query();
    if (!_au.next()) { response.setStatus(401); response.setBody({error:'Unauthorized'}); return; }
    var matchId = _au.getValue('u_match') || '';

    var body = request.body.data;
    var gr = new GlideRecord('x_887486_love_app_u_love_config');
    if (matchId) gr.addQuery('u_match', matchId);
    gr.query();
    var isNew = !gr.next();
    if (isNew) { gr.initialize(); if (matchId) gr.setValue('u_match', matchId); }

    if (body.mode            !== undefined) gr.setValue('u_mode',             body.mode);
    if (body.rewardTarget    !== undefined) gr.setValue('u_reward_target',    body.rewardTarget);
    if (body.punishThreshold !== undefined) gr.setValue('u_punish_threshold', body.punishThreshold);
    if (body.startDate       !== undefined) gr.setValue('u_start_date',       body.startDate);
    if (isNew) { gr.insert(); } else { gr.update(); }
    response.setBody({ success: true });
})(request, response);
