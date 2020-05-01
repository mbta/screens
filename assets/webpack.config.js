const path = require("path");
const glob = require("glob");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = (env, options) => ({
  resolve: {
    extensions: [".ts", ".tsx", ".js", ".jsx"],
    alias: {
      Components: path.resolve(__dirname, "src/components"),
      Hooks: path.resolve(__dirname, "src/hooks"),
      Util: path.resolve(__dirname, "src/util"),
      Constants: path.resolve(__dirname, "src/constants")
    }
  },
  entry: {
    polyfills: "./src/polyfills.js",
    bus_eink: "./src/apps/bus_eink.tsx",
    gl_eink_single: "./src/apps/gl_eink_single.tsx",
    gl_eink_double: "./src/apps/gl_eink_double.tsx",
    solari: "./src/apps/solari.tsx"
  },
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "../priv/static/js")
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
              "@babel/preset-typescript"
            ],
            plugins: [
              "@babel/plugin-proposal-export-default-from",
              "@babel/plugin-proposal-logical-assignment-operators",
              ["@babel/plugin-proposal-optional-chaining", { loose: false }],
              [
                "@babel/plugin-proposal-pipeline-operator",
                { proposal: "minimal" }
              ],
              [
                "@babel/plugin-proposal-nullish-coalescing-operator",
                { loose: false }
              ],
              "@babel/plugin-proposal-do-expressions"
            ]
          }
        }
      },
      {
        enforce: "pre",
        test: /\.js$/,
        loader: "source-map-loader"
      },
      {
        test: /\.s?css$/,
        use: [
          MiniCssExtractPlugin.loader,
          {
            loader: "css-loader"
          },
          {
            loader: "sass-loader"
          }
        ]
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: "../css/[name].css" }),
    new CopyWebpackPlugin([{ from: "static/", to: "../" }])
  ],
  devtool: "source-map",
  optimization: {
    minimizer: [
      new TerserPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  }
});
