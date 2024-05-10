## Using SVGs

We've started using an svg loader called SVGR that imports svgs as ready-to-use components! No longer do we need individual svgs with unique colors. Now, we can import an svg shape as a component and pass the relevant size and shape as props.

We're in the process of consolidating this huge assets folder of svgs into this `svgr_bundled` folder.

```
import Free from "Images/svgr_bundled/free.svg";

<Free width="128" height="128" className="free-cr" color="#171F26" />
```
