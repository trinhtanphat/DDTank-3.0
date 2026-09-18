# Yutikeyux DDTank 3.4 compatibility backport

Source: `yutikeyux/ddt-34-csharp@b90215e199ae079c05eb290ed1cbf2a2fb4bdf5e`

This batch adds 11 NPC AI classes directly referenced by live `Db_Tank_V30` and absent from the 158-script runtime. An alternate implementation set was tested because representative yutikeyux sources differ materially from the previously rejected barrydevp variants.

Candidate sieve: 158 DB-missing classes found; 147 rejected by the current 3.0 API/compiler; 11 survived together with the 158 canonical base. No yutikeyux core assemblies or unrelated content are imported.

## Upstream license notice

The copied portions are redistributed under the upstream MIT License from `yutikeyux/ddt-34-csharp`:

> MIT License
>
> Copyright (c) 2017 Ilya Meyta
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.
