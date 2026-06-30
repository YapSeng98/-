// RESOURCE 10: GET /history  |  Method: GET  |  Path: /history  |  Requires Authentication: FALSE
(function process(request, response) {
    var _tok = (request.getHeader('Authorization')||'').replace('Bearer ','').trim();
    var _au = new GlideRecord('x_887486_love_app_u_love_auth');
    _au.addQuery('u_api_key', _tok);
    _au.query();
    if (!_au.next()) { response.setStatus(401); response.setBody({error:'Unauthorized'}); return; }
    var matchId = _au.getValue('u_match') || '';

    var gr = new GlideRecord('x_887486_love_app_u_love_monthly');
    if (matchId) gr.addQuery('u_match', matchId);
    gr.orderByDesc('u_month');
    gr.setLimit(24);
    gr.query();
    var list = [];
    while (gr.next()) {
        list.push({
            month:     gr.getValue('u_month'),
            char1Pts:  parseInt(gr.getValue('u_char1_pts') || 0),
            char2Pts:  parseInt(gr.getValue('u_char2_pts') || 0),
            mode:      gr.getValue('u_mode'),
            result1:   gr.getValue('u_result_1'),
            result2:   gr.getValue('u_result_2'),
            settledAt: gr.getValue('u_settled_at'),
        });
    }
    response.setBody(list);
})(request, response);
