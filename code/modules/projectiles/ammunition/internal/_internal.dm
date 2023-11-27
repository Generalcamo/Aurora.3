/obj/item/ammo_magazine/internal
	abstract_type = /obj/item/ammo_magazine/internal
	desc = "This shouldn't be here."

//internals magazines are accessible, so replace spent ammo if full when trying to put a live one in
/obj/item/ammo_box/magazine/internal/give_round(obj/item/ammo_casing/R)
	return ..(R,1)
