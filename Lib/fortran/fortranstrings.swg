/* -------------------------------------------------------------------------
 * fortranstrings.swg
 *
 * C-string typemaps for native fortran conversion.
 * ------------------------------------------------------------------------- */

%include <fortranarray.swg>

/* -------------------------------------------------------------------------
 * FRAGMENTS
 * ------------------------------------------------------------------------- */
/* Return fortran allocatable array from assumed-length character string. Put a
 * null character *after* the string for compatibility with const char*.
 */
%fragment("SWIG_fin"{const char*}, "fsubprograms", fragment="SwigArrayWrapper_f", noblock=1) {
subroutine %fortrantm(fin, const char*)(finp, iminp, temp)
  use, intrinsic :: ISO_C_BINDING
  character(kind=C_CHAR, len=*), intent(in) :: finp
  type(SwigArrayWrapper), intent(out) :: iminp
  character(kind=C_CHAR), dimension(:), target, allocatable, intent(out) :: temp
  integer :: i

  allocate(character(kind=C_CHAR) :: temp(len(finp) + 1))
  do i=1,len(finp)
    temp(i) = finp(i:i)
  end do
  i = len(finp) + 1
  temp(i) = C_NULL_CHAR ! C finp compatibility
  iminp%data = c_loc(temp)
  iminp%size = len(finp)
end subroutine
}

// Copy string to character array
%fragment("SWIG_fargout"{char*}, "fsubprograms", fragment="SwigArrayWrapper_f", noblock=1) {
subroutine %fortrantm(fargout, char*)(chars, string)
  use, intrinsic :: ISO_C_BINDING
  character(kind=C_CHAR), dimension(:), intent(in) :: chars
  character(kind=C_CHAR, len=*), intent(out) :: string
  integer :: i
  do i=1, len(string)
    string(i:i) = chars(i)
  end do
end subroutine
}

// Return fortran allocatable string from character array
%fragment("SWIG_fout"{const char*}, "fsubprograms", fragment="SwigArrayWrapper_f", noblock=1) {
subroutine %fortrantm(fout, const char*)(imout, fout)
  use, intrinsic :: ISO_C_BINDING
  type(SwigArrayWrapper), intent(in) :: imout
  character(kind=C_CHAR, len=:), allocatable, intent(out) :: fout
  character(kind=C_CHAR), dimension(:), pointer :: chars
  integer(kind=C_SIZE_T) :: i
  call c_f_pointer(imout%data, chars, [imout%size])
  allocate(character(kind=C_CHAR, len=imout%size) :: fout)
  do i=1, imout%size
    fout(i:i) = chars(i)
  end do
end subroutine
}

/* -------------------------------------------------------------------------
 * C STRING TYPEMAPS
 *
 * By default, "const char*" and "char*" are automatically converted to and
 * from Fortran native strings.
 * ------------------------------------------------------------------------- */

%fortran_array(const char*)

// Since we add a final null character in "SWIG_fout"{const char*}, we can
// just access the data directly.
%typemap(in, noblock=1) const char * {
  $1 = %reinterpret_cast($input->data, $1_ltype);
}

// Save the outgoing string
%typemap(out, fragment="<stdlib.h>", fragment="<string.h>", noblock=1) const char * {
  $result.size = strlen(%reinterpret_cast($1, const char*));
  $result.data = %const_cast($1, $*1_ltype *);
}

// Fortran proxy code: return allocatable string
%typemap(ftype, in="character(kind=C_CHAR, len=*), target") const char *
  "character(kind=C_CHAR, len=:), allocatable"

%typemap(fin, fragment="SWIG_fin"{const char*}, noblock=1,
         temp="character(kind=C_CHAR), dimension(:), allocatable, target"
         ) const char * {
  call %fortrantm(fin, const char*)($input, $1, $1_temp)
}

// Fortran proxy translation code: convert from char array to Fortran string
%typemap(fout, fragment="SWIG_fout"{const char*}, fragment="SWIG_free_f", noblock=1) const char * {
  call %fortrantm(fout, const char*)($1, $result)
  if ($owner) call SWIG_free($1%data)
}

%apply const char* { char* };

/* -------------------------------------------------------------------------
 * BYTE ARRAY TYPEMAPS
 *
 * Transform (char *STRING, size_t LENGTH) to a byte array.
 *
 * Note that it's necessary to use a macro for %fortran_array to work correctly.
 * ------------------------------------------------------------------------- */

/* ISO interface type: pointer to templated array wrapper */
%fortran_array(%arg((char *STRING, size_t LENGTH)))

%typemap(in, noblock=1) (char *STRING, size_t LENGTH) {
  $1 = %reinterpret_cast($input->data, $1_ltype);
  $2 = $input->size;
}

%typemap(ftype, in="character(kind=C_CHAR, len=*), target") (char *STRING, size_t LENGTH)
  "character(kind=C_CHAR, len=:), allocatable"

%typemap(fin, fragment="SWIG_fin"{const char*}, noblock=1,
         temp="character(kind=C_CHAR), dimension(:), allocatable, target")
(char *STRING, size_t LENGTH) {
  call %fortrantm(fin, const char*)($input, $1, $1_temp)
}

// Fortran proxy translation code: convert from char array to Fortran string
%typemap(fout,
         fragment="SWIG_fout"{const char*}, fragment="SWIG_free_f", noblock=1) (char *STRING, size_t LENGTH) {
  call %fortrantm(fout, const char*)($1, $result)
  if ($owner) call SWIG_free($1%data)
}

%apply (char *STRING, size_t LENGTH) { (char *STRING, int LENGTH) }
