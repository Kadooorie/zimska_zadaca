# Getting started with Metal in Odin

Odin officially bundles with a low-overhead Odin interface for Metal that helps developers add Metal functionality to graphical applications, games, game engines, and GPU workload in Odin directly.

## Highlights

* Odin native drop interface as an alternative to the Metal in Objective-C or Swift
* Direct mapping of all Metal Objective-C classes, constants, and enumerations in Odin in `vendor:darwin/Metal`
* No measurable overhead compared to calling Metal in Objective-C, due to built-in compiler support for Objective-C operations
* No wrappers which do hidden memory allocations
* String `ErrorDomain` constants have weak linkage and are automatically set to `nil` if not available

## How to use

```odin
import NS  "vendor:darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA  "vendor:darwin/QuartzCore"
```

If you are using libraries for SDL2 from Homebrew, you may require adding some extra linker flags:
```
odin build . -extra-linker-flags:"-L/opt/homebrew/lib"
```

## Package Documentation

* https://pkg.odin-lang.org/vendor/darwin/Metal/
* https://pkg.odin-lang.org/vendor/darwin/Foundation/
* https://pkg.odin-lang.org/vendor/darwin/QuartzCore/

## Examples

### [00-window](https://github.com/odin-lang/examples/tree/master/learn_metal/00-window)

![00-window](https://user-images.githubusercontent.com/3338141/163404425-9e41168c-8f7f-4fd7-b7d9-c1c44a1d3870.png)

### [01-primitive](https://github.com/odin-lang/examples/tree/master/learn_metal/01-primitive)

![01-primitive](https://user-images.githubusercontent.com/3338141/163404549-0ece2502-1890-4bf6-b816-c0de3bfff303.png)

### [02-argbuffers](https://github.com/odin-lang/examples/tree/master/learn_metal/02-argbuffers)

![02-argbuffers](https://user-images.githubusercontent.com/3338141/163404646-bbb50869-303a-44d3-b039-1cc2d14b976e.png)

### [03-animation](https://github.com/odin-lang/examples/tree/master/learn_metal/03-animation)

![03-animation](https://user-images.githubusercontent.com/3338141/1634063