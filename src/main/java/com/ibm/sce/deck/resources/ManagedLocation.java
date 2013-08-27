package com.ibm.sce.deck.resources;

import java.util.Hashtable;

/**
 * Hold SCE Locations as Constants
 * 
 * @author Hai Liang BJ Wang/China/IBM May 10, 2013
 */
public class ManagedLocation {
	/** Holds the Index of the country objects. */
	private static final Hashtable<String, ManagedLocation> INDEX = new Hashtable<String, ManagedLocation>();
	/** Locations in SCE */
	public static final ManagedLocation BOULDER = new ManagedLocation("Boulder1", "82");
	public static final ManagedLocation EHNINGEN = new ManagedLocation("Ehningen", "61");
	public static final ManagedLocation MAKUHARI = new ManagedLocation("Makuhari", "121");
	public static final ManagedLocation MARKHAM = new ManagedLocation("Markham", "101");
	public static final ManagedLocation RALEIGH = new ManagedLocation("Raleigh", "41");
	public static final ManagedLocation SINGAPORE = new ManagedLocation("Singapore", "141");

	private static final String ERR_DUP_NAME = "ERROR: Constants of the same type have duplicate names."; //$NON-NLS-1$

	private final String name;
	private final String id;

	private ManagedLocation(final String name, final String id) {
		if (name == null | id == null) {
			throw new NullPointerException("The name and id may not be null."); //$NON-NLS-1$
		}
		if (INDEX.containsKey(name)) {
			throw new IllegalArgumentException(ERR_DUP_NAME);
		}
		this.name = name;
		this.id = id;
		INDEX.put(name, this);
	}

	/**
	 * Get the name of this location.
	 * 
	 * @return The name of the location.
	 */
	public String getName() {
		return this.name;
	}

	/**
	 * Get the id of this location.
	 * 
	 * @return The id of the location.
	 */
	public String getId() {
		return this.id;
	}

	/**
	 * Looks up a name to find the associated location object.
	 * 
	 * @param name
	 *            The name to lookup.
	 * 
	 * @return The object or null if it does not exist.
	 */
	public static ManagedLocation lookup(final String name) {
		return INDEX.get(name);
	}

	/**
	 * <p>
	 * Title: main
	 * </p>
	 * <p>
	 * Description:test location objects
	 * </p>
	 * 
	 * @param args
	 */
	// public static void main(String[] args) {
	//
	// System.out.println(Location.EHNINGEN.getId());
	// System.out.println(Location.EHNINGEN.getName());
	// System.out.println(Location.lookup("").getName());
	// }
}
