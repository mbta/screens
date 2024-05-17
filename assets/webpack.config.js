/* eslint-disable @typescript-eslint/no-var-requires */
/* global require, module, __dirname */

const path = require("path");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

const common_export_body = {
  resolve: {
    extensions: [".ts", ".tsx", ".js", ".jsx"],
    alias: {
      // Please also update the "paths" list in tsconfig.json when you add aliases here!
      Components: path.resolve(__dirname, "src/components"),
      Hooks: path.resolve(__dirname, "src/hooks"),
      Util: path.resolve(__dirname, "src/util"),
      Constants: path.resolve(__dirname, "src/constants"),
      Images: path.resolve(__dirname, "static/images"),
    },
  },
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "../priv/static/js"),
  },
  devtool: "source-map",
  optimization: {
    minimizer: [
      new TerserPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({}),
    ],
  },
};

const common_rules = [
  {
    enforce: "pre",
    test: /\.js$/,
    loader: "source-map-loader",
  },
  {
    test: /\.s?css$/,
    use: [
      MiniCssExtractPlugin.loader,
      {
        loader: "css-loader",
      },
      {
        loader: "sass-loader",
      },
    ],
  },
  {
    test: /\.svg$/i,
    issuer: /\.[jt]sx?$/,
    use: ["@svgr/webpack"],
  },
];

const common_babel_loader_plugins = [
  "@babel/plugin-proposal-export-default-from",
  "@babel/plugin-proposal-logical-assignment-operators",
  ["@babel/plugin-proposal-optional-chaining", { loose: false }],
  ["@babel/plugin-proposal-pipeline-operator", { proposal: "minimal" }],
  ["@babel/plugin-proposal-nullish-coalescing-operator", { loose: false }],
  "@babel/plugin-proposal-do-expressions",
];

module.exports = () => [
  {
    ...common_export_body,
    entry: {
      polyfills: "./src/polyfills.js",
      bus_eink: "./src/apps/bus_eink.tsx",
      gl_eink_single: "./src/apps/gl_eink_single.tsx",
      gl_eink_double: "./src/apps/gl_eink_double.tsx",
      solari: "./src/apps/solari.tsx",
      dup: "./src/apps/dup.tsx",
      admin: "./src/apps/admin.tsx",
      bus_eink_v2: "./src/apps/v2/bus_eink.tsx",
      gl_eink_v2: "./src/apps/v2/gl_eink.tsx",
      busway_v2: "./src/apps/v2/busway.tsx",
      solari_large_v2: "./src/apps/v2/solari_large.tsx",
      dup_v2: "./src/apps/v2/dup.tsx",
      bus_shelter_v2: "./src/apps/v2/bus_shelter.tsx",
      pre_fare_v2: "./src/apps/v2/pre_fare.tsx",
      triptych_v2: "./src/apps/v2/triptych.tsx",
    },
    module: {
      rules: [
        {
          test: /\.ts(x?)$/,
          exclude: /node_modules/,
          use: {
            loader: "babel-loader",
            options: {
              presets: [
                ["@babel/preset-env", { targets: "> 0.25%" }],
                "@babel/preset-react",
                "@babel/preset-typescript",
              ],
              plugins: common_babel_loader_plugins,
            },
          },
        },
        ...common_rules,
        {
          test: /\.(woff(2)?|ttf|eot)(\?v=\d+\.\d+\.\d+)?$/,
          use: [
            {
              loader: "file-loader",
              options: {
                name: "[name].[ext]",
                outputPath: "fonts/",
                publicPath: "../fonts/",
                useRelativePaths: true,
              },
            },
          ],
        },
        {
          test: /\.(png|jpe?g|gif)$/i,
          use: [
            {
              loader: "file-loader",
              options: {
                name: "[name].[ext]",
                outputPath: "/images/",
                publicPath: "/images/",
                useRelativePaths: true,
              },
            },
          ],
        },
        {
          test: /\.(webp)$/i,
          use: [
            {
              loader: "file-loader",
              options: {
                name: "/[folder]/[name].[ext]",
                outputPath: "/images/",
                publicPath: "/images/",
                useRelativePaths: true,
              },
            },
          ],
        },
      ],
    },
    plugins: [
      new MiniCssExtractPlugin({ filename: "../css/[name].css" }),
      new CopyWebpackPlugin({ patterns: [{ from: "static/", to: "../" }] }),
    ],
  },
  {
    ...common_export_body,
    entry: {
      packaged_triptych_polyfills: "./src/polyfills.js",
      packaged_triptych_v2: "./src/apps/v2/triptych.tsx",
    },
    module: {
      rules: [
        {
          test: /\.ts(x?)$/,
          exclude: /node_modules/,
          use: {
            loader: "babel-loader",
            options: {
              presets: [
                // When no targets are specified: Babel will assume you are targeting the oldest browsers possible.
                [
                  "@babel/preset-env",
                  {
                    corejs: { version: 3, proposals: true },
                    useBuiltIns: "usage",
                  },
                ],
                "@babel/preset-react",
                "@babel/preset-typescript",
              ],
              plugins: common_babel_loader_plugins,
            },
          },
        },
        ...common_rules,
        {
          test: /\.(woff(2)?|ttf|eot)(\?v=\d+\.\d+\.\d+)?$/,
          use: [
            {
              loader: "file-loader",
              options: {
                name: "[name].[ext]",
                outputPath: "fonts/",
                publicPath: "fonts/",
                useRelativePaths: true,
              },
            },
          ],
        },
        {
          test: /\.(png|jpe?g|gif)$/i,
          use: [
            {
              loader: "file-loader",

              options: {
                name: "[name].[ext]",
                outputPath: "triptych_images/",
                publicPath: "triptych_images/",
                useRelativePaths: true,
              },
            },
          ],
        },
        {
          test: /\.(webp)$/i,
          use: [
            {
              loader: "file-loader",
              options: {
                name: "/[folder]/[name].[ext]",
                outputPath: "triptych_images/triptych_psas/",
                publicPath: "triptych_images/triptych_psas/",
                useRelativePaths: true,
              },
            },
          ],
        },
      ],
    },
    plugins: [
      new MiniCssExtractPlugin({ filename: "../css/[name].css" }),
      new CopyWebpackPlugin({
        patterns: [{ from: "static/fonts", to: "../fonts" }],
      }),
    ],
  },
];
