// RESOURCE 1: GET /config  |  Method: GET  |  Path: /config  |  Requires Authentication: FALSE
(function process(request, response) {
    var _tok = (request.getHeader('Authorization')||'').replace('Bearer ','').trim();
    var _au = new GlideRecord('x_887486_love_app_u_love_auth');
    _au.addQuery('u_api_key', _tok);
    _au.query();
    if (!_au.next()) { response.setStatus(401); response.setBody({error:'Unauthorized'}); return; }
    var matchId = _au.getValue('u_match') || '';

    var gr = new GlideRecord('x_887486_love_app_u_love_config');
    if (matchId) gr.addQuery('u_match', matchId);
    gr.query();
    if (gr.next()) {
        response.setBody({
            configured:      true,
            mode:            gr.getValue('u_mode') || 'reward',
            rewardTarget:    parseInt(gr.getValue('u_reward_target'))    || 100,
            punishThreshold: parseInt(gr.getValue('u_punish_threshold')) || -80,
        });
    } else {
        response.setBody({ configured: false });
    }
})(request, response);
