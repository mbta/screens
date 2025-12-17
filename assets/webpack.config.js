/* eslint-disable @typescript-eslint/no-require-imports */
/* global require, module, __dirname */

const path = require("path");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const { sentryWebpackPlugin } = require("@sentry/webpack-plugin");

const ALIASES = {
  // See also `paths` in `tsconfig.json`!
  CSS: path.resolve(__dirname, "css"),
  Components: path.resolve(__dirname, "src/components"),
  Hooks: path.resolve(__dirname, "src/hooks"),
  Images: path.resolve(__dirname, "images"),
  Util: path.resolve(__dirname, "src/util"),
};

const ENTRYPOINTS = {
  admin: "./src/apps/admin.tsx",
  bus_eink: "./src/apps/bus_eink.tsx",
  bus_shelter: "./src/apps/bus_shelter.tsx",
  busway: "./src/apps/busway.tsx",
  dup: "./src/apps/dup.tsx",
  elevator: "./src/apps/elevator.tsx",
  gl_eink: "./src/apps/gl_eink.tsx",
  pre_fare: "./src/apps/pre_fare.tsx",
};

const STATIC_PATH = path.resolve(__dirname, "../priv/static");

// Though this is normally not recommended, we transpile the dependencies we
// ship to screens, because many libraries no longer support the old browser
// versions we have to support. This should be reevaluated with future shifts
// in the screens browser landscape.
// As noted in webpack documentation, core-js will cause errors if transpiled
// https://webpack.js.org/loaders/babel-loader/#exclude-libraries-that-should-not-be-transpiled
const BABEL_EXCLUDED_DEPS_PATTERN = new RegExp("node_modules/core-js");

module.exports = (env, argv) => {
  const isOutfrontPackage = env.package === "dup";
  const isProduction = argv.mode === "production";

  return {
    devtool: "source-map",
    entry: isOutfrontPackage
      ? { packaged_dup: "./src/apps/dup.tsx" }
      : ENTRYPOINTS,
    optimization: {
      minimizer: [new CssMinimizerPlugin(), new TerserPlugin()],
    },
    output: { filename: "js/[name].js", path: STATIC_PATH },
    module: {
      rules: [
        {
          test: /\.m?[jt]sx?$/,
          exclude: BABEL_EXCLUDED_DEPS_PATTERN,
          use: {
            loader: "babel-loader",
            options: {
              presets: [
                [
                  "@babel/preset-env",
                  {
                    targets: { chrome: 51 },
                    useBuiltIns: "usage",
                    corejs: require("core-js/package.json").version,
                  },
                ],
                // "automatic" will be the default in Babel 8
                ["@babel/preset-react", { runtime: "automatic" }],
                "@babel/preset-typescript",
              ],
              // plugins: ["transform-es2015-template-literal"],
              // only needed as long as we are transpiling dependencies
              sourceType: "unambiguous",
            },
          },
        },
        {
          test: /\.(js|mjs)$/,
          include: /node_modules\/react-router/,
          use: {
            loader: "babel-loader",
            options: {
              presets: [
                [
                  "@babel/preset-env",
                  {
                    targets: { chrome: "51" },
                    modules: false,
                  },
                ],
              ],
              plugins: [
                // Custom plugin to transform dynamic imports to require()
                // Transforms: import(module) -> Promise.resolve(require(module))
                // There are webpackIgnore comments at imports in react-router to
                // prevent webpack from code-splitting there.
                // However, it also prevents dynamic imports from being transpiled
                // This is needed for DUPs, which use Chrome 51.
                function (babel) {
                  const t = babel.types;
                  return {
                    name: "transform-dynamic-import-to-require",
                    visitor: {
                      CallExpression(path) {
                        if (
                          path.node.callee &&
                          path.node.callee.type === "Import"
                        ) {
                          const arg = path.node.arguments[0];
                          path.replaceWith(
                            t.callExpression(
                              t.memberExpression(
                                t.identifier("Promise"),
                                t.identifier("resolve"),
                              ),
                              [
                                arg
                                  ? t.callExpression(t.identifier("require"), [
                                      arg,
                                    ])
                                  : t.callExpression(
                                      t.identifier("require"),
                                      [],
                                    ),
                              ],
                            ),
                          );
                        }
                      },
                    },
                  };
                },
              ],
            },
          },
        },
        {
          test: /\.js$/,
          enforce: "pre",
          loader: "source-map-loader",
        },
        {
          test: /\.s?css$/,
          use: [
            MiniCssExtractPlugin.loader,
            { loader: "css-loader" },
            { loader: "sass-loader" },
          ],
        },
        {
          test: /\.svg$/i,
          issuer: /\.[jt]sx?$/,
          use: ["@svgr/webpack"],
        },
        {
          test: /\.(woff(2)?|ttf|eot)(\?v=\d+\.\d+\.\d+)?$/,
          type: "asset/resource",
          generator: {
            filename: "[base]",
            outputPath: "fonts/",
            // The DUP app packaging process moves the bundled CSS up a
            // directory level, which would break references to font files;
            // this compensates for that. See also `utils.imagePath`.
            publicPath: isOutfrontPackage ? "fonts/" : "../fonts/",
          },
        },
      ],
    },
    plugins: [
      new MiniCssExtractPlugin({ filename: "css/[name].css" }),
      new CopyWebpackPlugin({ patterns: [{ from: "static/", to: "./" }] }),
      // Upload source maps to Sentry for prod builds. Must be the last plugin.
      ...(isProduction
        ? [
            sentryWebpackPlugin({
              authToken: env.SENTRY_AUTH_TOKEN,
              org: env.SENTRY_ORG,
              project: env.SENTRY_PROJECT,
            }),
          ]
        : []),
    ],
    resolve: { alias: ALIASES, extensions: [".ts", ".tsx", ".js", ".jsx"] },
  };
};
