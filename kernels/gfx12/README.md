# gfx12 kernels (MI450 / MI400, CDNA-next)

Placeholder for the gfx12 kernel implementations. The cross-card memory backend
(VMM, in `src/peer_mem/`) is shared with gfx9; only the kernels themselves are
arch-specific and live here.

TODO: port allreduce / reduce-scatter to gfx12.
