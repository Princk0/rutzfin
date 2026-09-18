package com.rutzfin.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * Catch-all that forwards non-API, non-asset requests to index.html
 * so that React Router's client-side routes work after a page refresh.
 *
 * The pattern excludes paths that contain a dot (static assets like .js, .css)
 * so those are still served directly from classpath:/static/.
 */
@Controller
public class SpaController {

    @RequestMapping(value = {"/{path:[^\\.]*}", "/{path:[^\\.]*}/**"})
    public String spa() {
        return "forward:/index.html";
    }
}
