module differential_output (
    input  wire signal_in,

    output wire signal_p,
    output wire signal_n
);

    // Differential output implementation goes here.
TLVDS_OBUF instance_name (
    .I  (signal_in),
    .O  (signal_p),
    .OB (signal_n)
);


endmodule
