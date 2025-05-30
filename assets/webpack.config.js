/* eslint-disable @typescript-eslint/no-require-imports */
/* global require, module, __dirname */

const path = require("path");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
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
  bus_eink_v2: "./src/apps/v2/bus_eink.tsx",
  bus_shelter_v2: "./src/apps/v2/bus_shelter.tsx",
  busway_v2: "./src/apps/v2/busway.tsx",
  dup_v2: "./src/apps/v2/dup.tsx",
  elevator_v2: "./src/apps/v2/elevator.tsx",
  gl_eink_v2: "./src/apps/v2/gl_eink.tsx",
  pre_fare_v2: "./src/apps/v2/pre_fare.tsx",
};

const STATIC_PATH = path.resolve(__dirname, "../priv/static");

module.exports = (env, argv) => {
  const isOutfrontPackage = env.package == "dup";
  const isProduction = argv.mode == "production";

  return {
    devtool: "source-map",
    entry: isOutfrontPackage
      ? {
          packaged_dup_polyfills: "./src/polyfills.js",
          packaged_dup_v2: "./src/apps/v2/dup.tsx",
        }
      : {
          polyfills: "./src/polyfills.js",
          ...ENTRYPOINTS,
        },
    optimization: {
      minimizer: [new TerserPlugin(), new OptimizeCSSAssetsPlugin()],
    },
    output: { filename: "js/[name].js", path: STATIC_PATH },
    module: {
      rules: [
        {
          test: /\.ts(x?)$/,
          exclude: /node_modules/,
          use: {
            loader: "babel-loader",
            options: {
              presets: [
                [
                  "@babel/preset-env",
                  { targets: isOutfrontPackage ? undefined : "> 0.25%" },
                ],
                "@babel/preset-react",
                "@babel/preset-typescript",
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
          use: [
            {
              loader: "file-loader",
              options: {
                name: "[name].[ext]",
                outputPath: "fonts/",
                // The DUP app packaging process moves the bundled CSS up a
                // directory level, which would break references to font files;
                // this compensates for that. See also `utils.imagePath`.
                publicPath: isOutfrontPackage ? "fonts/" : "../fonts/",
              },
            },
          ],
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
