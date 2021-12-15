using XLSX, LinearAlgebra

data = XLSX.readxlsx("transfer_m.xlsx")

data = data["Sheet6"]
num = length(data["F"])
R_matrix = zeros(2, num)
I_matrix = zeros(2, num)

R_matrix[1, :] = data["F"]
R_matrix[2, :] = data["H"]

I_matrix[1, :] = data["B"]
I_matrix[2, :] = data["D"]

M = I_matrix * pinv(R_matrix)

@show(M)
