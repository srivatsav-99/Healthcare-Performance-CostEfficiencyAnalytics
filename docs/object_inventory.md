# \# Object Inventory

# 

# \---

# 

# \## Raw Tables

# \- raw\_hospital\_info

# \- raw\_hcahps

# \- raw\_complications

# \- raw\_infections

# \- raw\_readmissions

# \- raw\_spending

# \- raw\_timely\_care

# \- raw\_rural\_zip

# 

# \---

# 

# \## Staging Tables

# \- stg\_facility\_universe

# \- stg\_hospital\_info\_clean

# \- stg\_rural\_zip\_clean

# \- stg\_hcahps\_clean

# \- stg\_complications\_clean

# \- stg\_infections\_clean

# \- stg\_readmissions\_clean

# \- stg\_spending\_clean

# \- stg\_timely\_care\_clean

# \- stg\_ambiguous\_facilities

# 

# \---

# 

# \## Dimension Tables

# \- dim\_hospital

# \- dim\_measure

# 

# \---

# 

# \## Fact Tables

# \- fact\_hcahps

# \- fact\_complications

# \- fact\_infections

# \- fact\_readmissions

# \- fact\_spending

# \- fact\_timely\_care

# 

# \---

# 

# \## Analytical Views

# 

# \### Core Reference Views

# \- vw\_hospital\_master

# 

# \### Benchmark Views

# \- vw\_cost\_benchmark

# \- vw\_safety\_benchmark

# \- vw\_outcomes\_benchmark

# \- vw\_readmission\_benchmark

# \- vw\_patient\_experience\_benchmark

# 

# \### Aggregation \& Output Views

# \- vw\_hospital\_performance\_summary

# \- vw\_hospital\_performance\_export

