/* eslint-disable @typescript-eslint/no-require-imports */
/* global require, module, __dirname */

const path = require("path");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const { sentryWebpackPlugin } = require("@sentry/webpack-plugin");

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
    minimizer: [new TerserPlugin(), new OptimizeCSSAssetsPlugin()],
  },
};

function getCommonRules(isOfmPackage) {
  return [
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
    {
      test: /\.(png|jpe?g|gif|webp)$/i,
      use: [
        {
          loader: "file-loader",
          options: {
            name: "/[folder]/[name].[ext]",
            useRelativePaths: true,
          },
        },
      ],
    },
    {
      test: /\.(woff(2)?|ttf|eot)(\?v=\d+\.\d+\.\d+)?$/,
      use: [
        {
          loader: "file-loader",
          options: {
            name: "[name].[ext]",
            outputPath: "fonts/",
            publicPath: isOfmPackage ? "fonts/" : "../fonts/",
            useRelativePaths: true,
          },
        },
      ],
    },
  ];
}

const common_babel_loader_plugins = [
  "@babel/plugin-proposal-export-default-from",
  "@babel/plugin-proposal-logical-assignment-operators",
  ["@babel/plugin-proposal-optional-chaining", { loose: false }],
  ["@babel/plugin-proposal-pipeline-operator", { proposal: "minimal" }],
  ["@babel/plugin-proposal-nullish-coalescing-operator", { loose: false }],
  "@babel/plugin-proposal-do-expressions",
];

const common_plugins = [
  new MiniCssExtractPlugin({ filename: "../css/[name].css" }),
  new CopyWebpackPlugin({ patterns: [{ from: "static/", to: "../" }] }),
];

module.exports = (env, argv) => {
  const plugins =
    argv.mode == "production"
      ? [
          ...common_plugins,
          // Upload source maps to Sentry for prod builds. Must be the last plugin.
          sentryWebpackPlugin({
            authToken: env.SENTRY_AUTH_TOKEN,
            org: env.SENTRY_ORG,
            project: env.SENTRY_PROJECT,
          }),
        ]
      : common_plugins;

  return [
    {
      ...common_export_body,
      entry: {
        polyfills: "./src/polyfills.js",
        admin: "./src/apps/admin.tsx",
        bus_eink_v2: "./src/apps/v2/bus_eink.tsx",
        gl_eink_v2: "./src/apps/v2/gl_eink.tsx",
        busway_v2: "./src/apps/v2/busway.tsx",
        dup_v2: "./src/apps/v2/dup.tsx",
        bus_shelter_v2: "./src/apps/v2/bus_shelter.tsx",
        pre_fare_v2: "./src/apps/v2/pre_fare.tsx",
        elevator_v2: "./src/apps/v2/elevator.tsx",
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
          ...getCommonRules(false),
        ],
      },
      plugins: plugins,
    },
    {
      ...common_export_body,
      entry: {
        packaged_dup_polyfills: "./src/polyfills.js",
        packaged_dup_v2: "./src/apps/v2/dup.tsx",
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
          ...getCommonRules(true),
        ],
      },
      plugins: plugins,
    },
  ];
};
