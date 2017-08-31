exports.config = {
  files: {
    javascripts: { joinTo: "js/app.js" },
    stylesheets: { joinTo: "css/app.css" },
    templates: { joinTo: "js/app.js" }
  },
  conventions: { assets: /^(static)/ },
  paths: {
    watched: ["static", "css", "js", "vendor", "elm"],
    public: "../priv/static"
  },
  plugins: {
    babel: { ignore: [/vendor/] },
    elmBrunch: {
      mainModules: ["elm/Main.elm"],
      makeParameters: ["--debug"],
      outputFolder: "../assets/js"
    }
  },
  modules: {
    autoRequire: { "js/app.js": ["js/app"] }
  },
  npm: { enabled: true }
};
